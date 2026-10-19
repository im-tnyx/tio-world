import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_composition_repository.dart';
import 'supabase_routine_composition_gateway.dart';
import 'routine_move_delete_attempt_gate.dart';

typedef _Header = ({int revision, String? mutationId, String? name});

final class SupabaseRoutineCompositionRepository
    implements RoutineCompositionRepository, RoutineAggregateUpdateRepository {
  SupabaseRoutineCompositionRepository({
    required RoutineCompositionGateway gateway,
    required String? Function() currentUserId,
    RoutineMoveDeleteAttemptGate? crossOperationGate,
    int pageSize = 500,
    int readAttempts = 3,
    Duration requestTimeout = const Duration(seconds: 15),
  })  : _gateway = gateway,
        _currentUserId = currentUserId,
        _crossOperationGate = crossOperationGate,
        _pageSize = pageSize,
        _readAttempts = readAttempts,
        _requestTimeout = requestTimeout {
    if (pageSize <= 0 || readAttempts <= 0 || requestTimeout <= Duration.zero) {
      throw ArgumentError('Read bounds and timeout must be positive.');
    }
  }

  factory SupabaseRoutineCompositionRepository.fromClient(
    SupabaseClient client, {
    required RoutineMoveDeleteAttemptGate crossOperationGate,
  }) => SupabaseRoutineCompositionRepository(
        gateway: SupabaseRoutineCompositionGateway(client),
        currentUserId: () => client.auth.currentUser?.id,
        crossOperationGate: crossOperationGate,
      );

  final RoutineCompositionGateway _gateway;
  final String? Function() _currentUserId;
  final RoutineMoveDeleteAttemptGate? _crossOperationGate;
  final int _pageSize;
  final int _readAttempts;
  final Duration _requestTimeout;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId routineId) async {
    final owner = _owner();
    final snapshot = await _read(routineId, owner);
    // Bracketed authenticated owner reads of a *later* CAS revision are
    // positive evidence that an earlier UNKNOWN write cannot still commit.
    // Missing/same-revision/failed reads deliberately never clear the gate.
    if (snapshot != null) {
      _crossOperationGate?.observeRevision(owner, routineId, snapshot.revision);
    }
    return snapshot;
  }

  /// Both composition-only Save and Name+composition Update use the same
  /// process-local reservation as Routine Move/Delete. Never treat it as
  /// a substitute for the server-side owner/RLS and revision checks.
  Future<int> _reserveForEdit(
    RoutineId routineId,
    int expectedRevision,
    Future<int> Function() dispatch,
  ) async {
    final gate = _crossOperationGate;
    if (gate == null) return dispatch();
    final owner = _owner();
    if (!gate.tryStart(owner, routineId)) {
      // No Edit RPC was sent. This is a definite local conflict, never
      // a fabricated unconfirmed mutation or license to retry blindly.
      throw const RoutineCompositionException(
          RoutineCompositionFailureKind.readConflict);
    }
    try {
      return await dispatch();
    } on RoutineCompositionSaveOutcomeUnknown {
      // A late RPC can still commit after this adapter or route is rebuilt.
      // Preserve the frozen old revision even if the owner's login changed.
      gate.markUncertain(owner, routineId, expectedRevision);
      rethrow;
    } finally {
      gate.finish(owner, routineId);
    }
  }

  Future<RoutineCompositionSnapshot?> _read(
      RoutineId routineId, String owner) async {
    for (var attempt = 0; attempt < _readAttempts; attempt++) {
      final start = await _readRequest(owner,
          () => _gateway.readHeader(userId: owner, routineId: routineId.value));
      if (start == null) return null;
      final before = _header(start, routineId, owner);
      List<Map<String, dynamic>> entries = const [];
      List<Map<String, dynamic>> sets = const [];
      RoutineCompositionException? provisionalFailure;
      try {
        entries = await _pages(
            owner,
            (cursor) => _gateway.readEntries(
                userId: owner,
                routineId: routineId.value,
                limit: _pageSize,
                afterId: cursor));
        sets = await _pages(
            owner,
            (cursor) => _gateway.readSets(
                userId: owner,
                routineId: routineId.value,
                limit: _pageSize,
                afterId: cursor));
      } on RoutineCompositionException catch (error) {
        if (error.kind != RoutineCompositionFailureKind.malformedData) rethrow;
        provisionalFailure = error;
      }
      final end = await _readRequest(owner,
          () => _gateway.readHeader(userId: owner, routineId: routineId.value));
      if (end == null) return null;
      final after = _header(end, routineId, owner);
      if (before != after) continue;
      if (provisionalFailure != null) throw provisionalFailure;
      // Decode only after the bracket: intermediate pages may mix revisions.
      final snapshot = _snapshot(routineId, owner, after, entries, sets);
      _checkOwner(owner);
      return snapshot;
    }
    throw const RoutineCompositionException(
        RoutineCompositionFailureKind.readConflict);
  }

  Future<List<Map<String, dynamic>>> _pages(
    String owner,
    Future<List<Map<String, dynamic>>> Function(String?) fetch,
  ) async {
    final rows = <Map<String, dynamic>>[];
    String? cursor;
    while (true) {
      final page = await _readRequest(owner, () => fetch(cursor));
      if (page.isEmpty) return rows;
      if (page.length > _pageSize) throw _malformed;
      for (final row in page) {
        final id = _uuid(row['id']);
        if (cursor != null && id.compareTo(cursor) <= 0) throw _malformed;
        cursor = id;
        rows.add(row);
      }
      // A short page is not EOF: the hosted cap may be below _pageSize.
    }
  }

  @override
  Future<int> save(RoutineCompositionSave command) => _reserveForEdit(
        command.routineId, command.expectedRevision,
        () => _save(command),
      );

  Future<int> _save(RoutineCompositionSave command) async {
    final owner = _owner();
    Object? result;
    try {
      _checkOwner(owner);
      result = await _gateway
          .save(
            routineId: command.routineId.value,
            expectedRevision: command.expectedRevision,
            mutationId: command.mutationId,
            exercises: payload(command),
          )
          .timeout(_requestTimeout);
    } on PostgrestException catch (error) {
      if (!_sameOwner(owner) || _ambiguous(error)) {
        return _reconcile(command, owner);
      }
      throw _rpcFailure(error);
    } catch (_) {
      return _reconcile(command, owner);
    }
    if (!_sameOwner(owner)) throw _authOutcomeUnknown;
    // The same-token RPC branch precedes revision comparison. Do not impose
    // expectedRevision + 1 on an explicitly successful idempotent response.
    if (result is int && result > 0) return result;
    return _reconcile(command, owner);
  }

  /// One frozen versioned server-side transaction. Never fall back to
  /// two separate Flutter writes (metadata Rename + composition Save).
  @override
  Future<int> updateAggregate(RoutineAggregateUpdate command) =>
      _reserveForEdit(
        command.routineId, command.expectedRevision,
        () => _updateAggregate(command),
      );

  Future<int> _updateAggregate(RoutineAggregateUpdate command) async {
    final owner = _owner();
    final gateway = _gateway;
    if (gateway is! RoutineAggregateUpdateGateway) {
      throw const RoutineCompositionException(
          RoutineCompositionFailureKind.unavailable);
    }
    Object? result;
    try {
      _checkOwner(owner);
      final exercises = command.entries == null
          ? null
          : payload(RoutineCompositionSave(
              routineId: command.routineId,
              expectedRevision: command.expectedRevision,
              mutationId: command.mutationId,
              entries: command.entries!,
              expectedCustomTypes: command.expectedCustomTypes,
            ));
      result = await (gateway as RoutineAggregateUpdateGateway).updateAggregate(
        routineId: command.routineId.value,
        programId: command.programId.value,
        expectedRevision: command.expectedRevision,
        expectedName: command.expectedName,
        mutationId: command.mutationId,
        name: command.name,
        exercises: exercises,
      ).timeout(_requestTimeout);
    } on PostgrestException catch (error) {
      if (!_sameOwner(owner) || _ambiguous(error)) {
        return _reconcileAggregate(command, owner);
      }
      throw _rpcFailure(error);
    } on RoutineCompositionException {
      rethrow;
    } catch (_) {
      return _reconcileAggregate(command, owner);
    }
    if (!_sameOwner(owner)) throw _authOutcomeUnknown;
    if (result is int && result > 0) return result;
    return _reconcileAggregate(command, owner);
  }

  Future<int> _reconcileAggregate(
      RoutineAggregateUpdate command, String owner) async {
    if (!_sameOwner(owner)) throw _authOutcomeUnknown;
    RoutineCompositionSnapshot? current;
    try {
      current = await _read(command.routineId, owner);
    } catch (_) {
      if (!_sameOwner(owner)) throw _authOutcomeUnknown;
      throw const RoutineCompositionSaveOutcomeUnknown();
    }
    if (!_sameOwner(owner)) throw _authOutcomeUnknown;
    if (current?.lastMutationId == command.mutationId) {
      if (!command.matches(current!)) {
        throw const RoutineCompositionException(
            RoutineCompositionFailureKind.mutationConflict);
      }
      if (current.revision == command.expectedRevision + 1) {
        return current.revision;
      }
    }
    throw RoutineCompositionSaveOutcomeUnknown(
      observedRevision: current?.revision,
      reason: current != null &&
              current.revision > command.expectedRevision &&
              current.lastMutationId != command.mutationId
          ? RoutineCompositionSaveUncertainty.superseded
          : RoutineCompositionSaveUncertainty.unconfirmed,
    );
  }

  Future<int> _reconcile(RoutineCompositionSave command, String owner) async {
    if (!_sameOwner(owner)) throw _authOutcomeUnknown;
    RoutineCompositionSnapshot? current;
    try {
      current = await _read(command.routineId, owner);
    } catch (_) {
      if (!_sameOwner(owner)) throw _authOutcomeUnknown;
      throw const RoutineCompositionSaveOutcomeUnknown();
    }
    if (!_sameOwner(owner)) throw _authOutcomeUnknown;
    if (current?.lastMutationId == command.mutationId) {
      if (!current!.hasSameContent(command)) {
        throw const RoutineCompositionException(
            RoutineCompositionFailureKind.mutationConflict);
      }
      if (current.revision == command.expectedRevision + 1) {
        return current.revision;
      }
    }
    throw RoutineCompositionSaveOutcomeUnknown(
      observedRevision: current?.revision,
      reason: current != null &&
              current.revision > command.expectedRevision &&
              current.lastMutationId != command.mutationId
          ? RoutineCompositionSaveUncertainty.superseded
          : RoutineCompositionSaveUncertainty.unconfirmed,
    );
  }

  Future<T> _readRequest<T>(String owner, Future<T> Function() request) async {
    _checkOwner(owner);
    try {
      final result = await request().timeout(_requestTimeout);
      _checkOwner(owner);
      return result;
    } on RoutineCompositionException {
      rethrow;
    } on PostgrestException catch (error) {
      _checkOwner(owner);
      final status = int.tryParse(error.code ?? '');
      if (status != null && status >= 200 && status <= 299) {
        throw _malformed;
      }
      throw _rpcFailure(error);
    } on FormatException {
      _checkOwner(owner);
      throw _malformed;
    } on TypeError {
      _checkOwner(owner);
      throw _malformed;
    } catch (_) {
      _checkOwner(owner);
      throw const RoutineCompositionException(
          RoutineCompositionFailureKind.unavailable);
    }
  }

  String _owner() {
    final id = _currentUserId()?.trim();
    if (id == null || !_uuidPattern.hasMatch(id)) {
      throw const RoutineCompositionException(
          RoutineCompositionFailureKind.unauthorized);
    }
    return id.toLowerCase();
  }

  bool _sameOwner(String owner) =>
      _currentUserId()?.trim().toLowerCase() == owner;

  void _checkOwner(String owner) {
    if (!_sameOwner(owner)) {
      throw const RoutineCompositionException(
          RoutineCompositionFailureKind.unauthorized);
    }
  }

  static _Header _header(
      Map<String, dynamic> row, RoutineId routine, String owner) {
    _owned(row, owner);
    if (_uuid(row['id']) != routine.value ||
        !row.containsKey('last_composition_mutation_id')) {
      throw _malformed;
    }
    final revision = row['composition_revision'];
    if (revision is! int || revision < 0) throw _malformed;
    return (
      revision: revision,
      mutationId: row['last_composition_mutation_id'] == null
          ? null
          : _uuid(row['last_composition_mutation_id']),
      // Legacy test fakes may omit name; a new name-aware operation must
      // require it for both exact post-write verification and CAS.
      name: row['name'] == null
          ? null
          : row['name'] is String && (row['name'] as String).trim().isNotEmpty
              ? row['name'] as String
              : throw _malformed,
    );
  }

  static RoutineCompositionSnapshot _snapshot(
    RoutineId routine,
    String owner,
    _Header header,
    List<Map<String, dynamic>> entryRows,
    List<Map<String, dynamic>> setRows,
  ) {
    final entries = List<Map<String, dynamic>>.of(entryRows)
      ..sort(
          (a, b) => _integer(a['position']).compareTo(_integer(b['position'])));
    final entryIds = <String>{};
    final grouped = <String, List<Map<String, dynamic>>>{};
    for (var position = 0; position < entries.length; position++) {
      final row = entries[position];
      _owned(row, owner);
      if (_uuid(row['routine_id']) != routine.value ||
          _integer(row['position']) != position ||
          !entryIds.add(_uuid(row['id']))) {
        throw _malformed;
      }
    }
    final setIds = <String>{};
    for (final row in setRows) {
      _owned(row, owner);
      final parent = _uuid(row['routine_exercise_id']);
      final joined = row['entry'];
      if (joined is! Map<String, dynamic>) throw _malformed;
      _owned(joined, owner);
      if (!entryIds.contains(parent) ||
          _uuid(joined['id']) != parent ||
          _uuid(joined['routine_id']) != routine.value ||
          !setIds.add(_uuid(row['id']))) {
        throw _malformed;
      }
      (grouped[parent] ??= []).add(row);
    }
    try {
      return RoutineCompositionSnapshot(
        routineId: routine,
        revision: header.revision,
        lastMutationId: header.mutationId,
        name: header.name,
        entries: entries.map((row) {
          if (!row.containsKey('catalog_exercise_id') ||
              !row.containsKey('user_exercise_id')) {
            throw _malformed;
          }
          final catalog = row['catalog_exercise_id'];
          final custom = row['user_exercise_id'];
          if ((catalog == null) == (custom == null)) throw _malformed;
          final ExerciseRef reference;
          if (catalog != null) {
            if (catalog is! String) throw _malformed;
            reference = ExerciseRef.catalog(catalog);
          } else {
            reference = ExerciseRef.userCreated(_uuid(custom));
          }
          final rows = grouped[_uuid(row['id'])] ?? [];
          rows.sort((a, b) =>
              _integer(a['position']).compareTo(_integer(b['position'])));
          return RoutineCompositionEntry(
            id: _uuid(row['id']),
            exercise: reference,
            sets: [for (var i = 0; i < rows.length; i++) _set(rows[i], i)],
          );
        }).toList(growable: false),
      );
    } on ArgumentError {
      throw _malformed;
    }
  }

  static RoutineCompositionSet _set(Map<String, dynamic> row, int position) {
    if (_integer(row['position']) != position ||
        !row.containsKey('reps') ||
        !row.containsKey('load_kg') ||
        !row.containsKey('rest_seconds') ||
        !row.containsKey('distance_meters') ||
        !row.containsKey('duration_seconds') ||
        !row.containsKey('set_type') ||
        !row.containsKey('reps_max')) {
      throw _malformed;
    }
    final repsValue = row['reps'];
    final int? reps = repsValue == null ? null : _integer(repsValue);
    if (reps == 0) throw _malformed;
    final load = row['load_kg'];
    final distance = row['distance_meters'];
    final durationValue = row['duration_seconds'];
    final max = row['reps_max'];
    final type = row['set_type'];
    // Decode after the bracketed read, fail closed on malformed hosted data.
    if (type is! String ||
        !RoutineSetType.values.any((value) => value.wireValue == type) ||
        (max != null &&
            (reps == null ||
             max is! int || max < reps || max > 2147483647))) {
      throw _malformed;
    }
    if (load != null &&
        (load is! num || !load.toDouble().isFinite || load < 0)) {
      throw _malformed;
    }
    if (distance != null &&
        (distance is! num || !distance.toDouble().isFinite || distance < 0)) {
      throw _malformed;
    }
    if (durationValue != null &&
        (durationValue is! int ||
         durationValue < 0 || durationValue > 2147483647)) {
      throw _malformed;
    }
    try {
      return RoutineCompositionSet(
        id: _uuid(row['id']),
        prescription: SetPrescription(
          reps: reps,
          repsMax: max as int?,
          setType: RoutineSetType.fromWire(type),
          loadKg: (load as num?)?.toDouble(),
          distanceMeters: (distance as num?)?.toDouble(),
          durationSeconds: durationValue as int?,
          restSeconds: row['rest_seconds'] == null
              ? null
              : _integer(row['rest_seconds']),
        ),
      );
    } on ArgumentError {
      throw _malformed;
    }
  }

  static void _owned(Map<String, dynamic> row, String owner) {
    if (_uuid(row['user_id']) != owner) {
      throw const RoutineCompositionException(
          RoutineCompositionFailureKind.forbidden);
    }
  }

  static int _integer(Object? value) {
    if (value is! int || value < 0 || value > 2147483647) throw _malformed;
    return value;
  }

  static final _uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');

  static String _uuid(Object? value) {
    if (value is! String || !_uuidPattern.hasMatch(value)) throw _malformed;
    return value.toLowerCase();
  }

  static List<Map<String, dynamic>> payload(RoutineCompositionSave command) =>
      [
        for (final entry in command.entries)
          {
            'id': entry.id,
            'exercise_ref': entry.exercise.value,
            if (command.expectedCustomTypes.containsKey(entry.id))
              'expected_exercise_type':
                  command.expectedCustomTypes[entry.id]?.storageValue,
            'sets': [
              for (final set in entry.sets)
                {
                  'id': set.id,
                  'reps': set.prescription.reps,
                  'reps_max': set.prescription.repsMax,
                  'set_type': set.prescription.setType.wireValue,
                  'load_kg': set.prescription.loadKg,
                  'distance_meters': set.prescription.distanceMeters,
                  'duration_seconds': set.prescription.durationSeconds,
                  'rest_seconds': set.prescription.restSeconds,
                }
            ],
          },
      ];

  static bool _ambiguous(PostgrestException error) {
    final status = int.tryParse(error.code ?? '');
    // The SDK reports an undecodable successful response using its HTTP 2xx
    // code. Such a response cannot prove that the atomic write rolled back.
    return (error.code?.isEmpty ?? true) ||
        (error.code?.startsWith('08') ?? false) ||
        (status != null &&
            ((status >= 200 && status <= 299) ||
                (status >= 500 && status <= 599)));
  }

  static RoutineCompositionException _rpcFailure(PostgrestException error) {
    final kind = switch (error.code) {
      '28000' ||
      '28P01' ||
      '401' ||
      'PGRST301' ||
      'PGRST302' ||
      'PGRST303' =>
        RoutineCompositionFailureKind.unauthorized,
      '42501' || '403' => RoutineCompositionFailureKind.forbidden,
      'P0002' when error.message == 'routine_update_not_found' =>
        RoutineCompositionFailureKind.notFound,
      'P0002' when error.message == 'routine_composition_not_found' =>
        RoutineCompositionFailureKind.notFound,
      'P0002' when error.message == 'routine_composition_exercise_not_found' =>
        RoutineCompositionFailureKind.exerciseUnavailable,
      'P0001' when error.message == 'routine_update_revision_conflict' =>
        RoutineCompositionFailureKind.revisionConflict,
      'P0001' when error.message == 'routine_update_mutation_conflict' =>
        RoutineCompositionFailureKind.mutationConflict,
      'P0001' when error.message == 'routine_composition_revision_conflict' =>
        RoutineCompositionFailureKind.revisionConflict,
      'P0001' when error.message == 'routine_composition_mutation_conflict' =>
        RoutineCompositionFailureKind.mutationConflict,
      // #534: a race against Custom archive is a DEFINITE no-write rejection.
      // Reuse the existing sanitized category; do not leak raw SQL details.
      '22023' when error.message ==
              'routine_composition_archived_exercise_modified' =>
        RoutineCompositionFailureKind.exerciseUnavailable,
      '22023' ||
      '22P02' ||
      '22003' ||
      '23514' =>
        RoutineCompositionFailureKind.invalidRequest,
      '23503' || '23505' => RoutineCompositionFailureKind.integrityConflict,
      _ => RoutineCompositionFailureKind.unavailable,
    };
    return RoutineCompositionException(kind);
  }

  static const _malformed =
      RoutineCompositionException(RoutineCompositionFailureKind.malformedData);
  static const _authOutcomeUnknown = RoutineCompositionSaveOutcomeUnknown(
      reason: RoutineCompositionSaveUncertainty.authChanged);
}

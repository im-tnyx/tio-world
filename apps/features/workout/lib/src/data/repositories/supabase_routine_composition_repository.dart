import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_composition_repository.dart';
import 'supabase_routine_composition_gateway.dart';

typedef _Header = ({int revision, String? mutationId});

final class SupabaseRoutineCompositionRepository
    implements RoutineCompositionRepository {
  SupabaseRoutineCompositionRepository({
    required RoutineCompositionGateway gateway,
    required String? Function() currentUserId,
    int pageSize = 500,
    int readAttempts = 3,
    Duration requestTimeout = const Duration(seconds: 15),
  })  : _gateway = gateway,
        _currentUserId = currentUserId,
        _pageSize = pageSize,
        _readAttempts = readAttempts,
        _requestTimeout = requestTimeout {
    if (pageSize <= 0 || readAttempts <= 0 || requestTimeout <= Duration.zero) {
      throw ArgumentError('Read bounds and timeout must be positive.');
    }
  }

  factory SupabaseRoutineCompositionRepository.fromClient(
          SupabaseClient client) =>
      SupabaseRoutineCompositionRepository(
        gateway: SupabaseRoutineCompositionGateway(client),
        currentUserId: () => client.auth.currentUser?.id,
      );

  final RoutineCompositionGateway _gateway;
  final String? Function() _currentUserId;
  final int _pageSize;
  final int _readAttempts;
  final Duration _requestTimeout;

  @override
  Future<RoutineCompositionSnapshot?> read(RoutineId routineId) async =>
      await _read(routineId, _owner());

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
  Future<int> save(RoutineCompositionSave command) async {
    final owner = _owner();
    Object? result;
    try {
      _checkOwner(owner);
      result = await _gateway
          .save(
            routineId: command.routineId.value,
            expectedRevision: command.expectedRevision,
            mutationId: command.mutationId,
            exercises: _payload(command),
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
          : _uuid(row['last_composition_mutation_id'])
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
        !row.containsKey('load_kg') ||
        !row.containsKey('rest_seconds')) {
      throw _malformed;
    }
    final reps = _integer(row['reps']);
    if (reps == 0) throw _malformed;
    final load = row['load_kg'];
    if (load != null &&
        (load is! num || !load.toDouble().isFinite || load < 0)) {
      throw _malformed;
    }
    return RoutineCompositionSet(
        id: _uuid(row['id']),
        prescription: SetPrescription(
          reps: reps,
          loadKg: (load as num?)?.toDouble(),
          restSeconds: row['rest_seconds'] == null
              ? null
              : _integer(row['rest_seconds']),
        ));
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

  static List<Map<String, dynamic>> _payload(RoutineCompositionSave command) =>
      [
        for (final entry in command.entries)
          {
            'id': entry.id,
            'exercise_ref': entry.exercise.value,
            'sets': [
              for (final set in entry.sets)
                {
                  'id': set.id,
                  'reps': set.prescription.reps,
                  'load_kg': set.prescription.loadKg,
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
      '28000' || '28P01' || '401' => RoutineCompositionFailureKind.unauthorized,
      '42501' || '403' => RoutineCompositionFailureKind.forbidden,
      'P0002' when error.message == 'routine_composition_not_found' =>
        RoutineCompositionFailureKind.notFound,
      'P0002' when error.message == 'routine_composition_exercise_not_found' =>
        RoutineCompositionFailureKind.exerciseUnavailable,
      'P0001' when error.message == 'routine_composition_revision_conflict' =>
        RoutineCompositionFailureKind.revisionConflict,
      'P0001' when error.message == 'routine_composition_mutation_conflict' =>
        RoutineCompositionFailureKind.mutationConflict,
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

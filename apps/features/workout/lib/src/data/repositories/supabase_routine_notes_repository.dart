import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/repositories/routine_notes_repository.dart';

abstract interface class RoutineNotesGateway {
  Future<List<Map<String, dynamic>>> read({
    required String userId,
    required RoutineNoteScope scope,
  });

  Future<Map<String, dynamic>> mutate(Map<String, dynamic> params);

  Future<Map<String, dynamic>> reconcile({required String mutationId});
}

final class SupabaseRoutineNotesGateway implements RoutineNotesGateway {
  const SupabaseRoutineNotesGateway(this._client);

  final SupabaseClient _client;

  @override
  Future<List<Map<String, dynamic>>> read({
    required String userId,
    required RoutineNoteScope scope,
  }) async {
    var query = _client
        .from('user_workout_routine_notes')
        .select(
          'id,user_id,routine_id,exercise_ref,note_type,body,created_at,'
          'updated_at,revision,last_mutation_id',
        )
        .eq('user_id', userId);
    query = scope.routineId != null
        ? query.eq('routine_id', scope.routineId!.value)
        : query.eq('exercise_ref', scope.exerciseRef!.value);
    final rows = await query
        .order('created_at', ascending: true)
        .order('id', ascending: true)
        .retry(enabled: false);
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> mutate(Map<String, dynamic> params) async {
    final response = await _client
        .rpc<Object?>('mutate_user_workout_routine_note', params: params)
        .retry(enabled: false);
    return _map(response);
  }

  @override
  Future<Map<String, dynamic>> reconcile({required String mutationId}) async {
    final response = await _client.rpc<Object?>(
      'reconcile_user_workout_routine_note_mutation',
      params: {'p_mutation_id': mutationId},
    ).retry(enabled: false);
    return _map(response);
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is! Map) {
      throw const FormatException('Malformed Routine Note RPC response.');
    }
    return Map<String, dynamic>.from(value);
  }
}

final class SupabaseRoutineNotesRepository implements RoutineNotesRepository {
  SupabaseRoutineNotesRepository({
    required RoutineNotesGateway gateway,
    required String? Function() currentUserId,
    Duration timeout = const Duration(seconds: 15),
  })  : _gateway = gateway,
        _currentUserId = currentUserId,
        _timeout = timeout {
    if (timeout <= Duration.zero) throw ArgumentError.value(timeout, 'timeout');
  }

  factory SupabaseRoutineNotesRepository.fromClient({
    required SupabaseClient client,
    Duration timeout = const Duration(seconds: 15),
  }) =>
      SupabaseRoutineNotesRepository(
        gateway: SupabaseRoutineNotesGateway(client),
        currentUserId: () => client.auth.currentUser?.id,
        timeout: timeout,
      );

  final RoutineNotesGateway _gateway;
  final String? Function() _currentUserId;
  final Duration _timeout;

  @override
  Future<List<RoutineNote>> read(RoutineNoteScope scope) async {
    final owner = _owner();
    try {
      final rows =
          await _gateway.read(userId: owner, scope: scope).timeout(_timeout);
      _checkOwner(owner);
      final notes = rows.map(RoutineNote.fromJson).toList(growable: false);
      for (final note in notes) {
        if (note.userId != owner || note.scope != scope) {
          throw const RoutineNoteException(
            RoutineNoteFailureKind.malformedData,
          );
        }
      }
      return notes;
    } on RoutineNoteException {
      rethrow;
    } on PostgrestException catch (error) {
      throw RoutineNoteException(
          _definite(error) ?? RoutineNoteFailureKind.unavailable);
    } on TimeoutException {
      throw const RoutineNoteException(RoutineNoteFailureKind.unavailable);
    } on FormatException {
      throw const RoutineNoteException(RoutineNoteFailureKind.malformedData);
    } catch (_) {
      throw const RoutineNoteException(RoutineNoteFailureKind.unavailable);
    }
  }

  @override
  Future<RoutineNote> create(RoutineNoteCreate command) async {
    final result = await _mutate(_createParams(command), command.mutationId);
    return _noteResult(result);
  }

  @override
  Future<RoutineNote> update(RoutineNoteUpdate command) async {
    final result = await _mutate(_updateParams(command), command.mutationId);
    return _noteResult(result);
  }

  @override
  Future<RoutineNote> transfer(RoutineNoteTransfer command) async {
    final result = await _mutate(_transferParams(command), command.mutationId);
    return _noteResult(result);
  }

  @override
  Future<void> delete(RoutineNoteDelete command) async {
    final result = await _mutate(_deleteParams(command), command.mutationId);
    if (result['status'] == 'expired') {
      throw const RoutineNoteException(RoutineNoteFailureKind.expired);
    }
    if (result['status'] != 'deleted') {
      throw const RoutineNoteException(RoutineNoteFailureKind.malformedData);
    }
  }

  Future<Map<String, dynamic>> _mutate(
    Map<String, dynamic> params,
    String mutationId,
  ) async {
    final owner = _owner();
    try {
      final result = await _gateway.mutate(params).timeout(_timeout);
      _checkOwner(owner, mutationId: mutationId);
      return result;
    } on RoutineNoteException {
      rethrow;
    } on PostgrestException catch (error) {
      final definite = _definite(error);
      if (definite != null) throw RoutineNoteException(definite);
      return _reconcile(owner, mutationId);
    } on TimeoutException {
      return _reconcile(owner, mutationId);
    } catch (_) {
      return _reconcile(owner, mutationId);
    }
  }

  Future<Map<String, dynamic>> _reconcile(
    String owner,
    String mutationId,
  ) async {
    if (!_sameOwner(owner)) {
      throw RoutineNoteOutcomeUnknown(
        mutationId: mutationId,
        reason: RoutineNoteUncertainty.sessionChanged,
      );
    }
    try {
      final result =
          await _gateway.reconcile(mutationId: mutationId).timeout(_timeout);
      if (!_sameOwner(owner)) {
        throw RoutineNoteOutcomeUnknown(
          mutationId: mutationId,
          reason: RoutineNoteUncertainty.sessionChanged,
        );
      }
      final status = result['status'];
      if (status == 'pending') {
        throw RoutineNoteOutcomeUnknown(mutationId: mutationId);
      }
      if (status == 'expired') {
        throw const RoutineNoteException(RoutineNoteFailureKind.expired);
      }
      if (status == 'applied' || status == 'deleted') return result;
      throw const RoutineNoteException(RoutineNoteFailureKind.malformedData);
    } on RoutineNoteOutcomeUnknown {
      rethrow;
    } on RoutineNoteException {
      rethrow;
    } on PostgrestException catch (error) {
      final definite = _definite(error);
      if (definite != null) throw RoutineNoteException(definite);
      throw RoutineNoteOutcomeUnknown(mutationId: mutationId);
    } on TimeoutException {
      throw RoutineNoteOutcomeUnknown(mutationId: mutationId);
    } catch (_) {
      throw RoutineNoteOutcomeUnknown(mutationId: mutationId);
    }
  }

  Map<String, dynamic> _createParams(RoutineNoteCreate command) => {
        'p_operation': 'create',
        'p_note_id': command.id,
        'p_routine_id': command.scope.routineId?.value,
        'p_exercise_ref': command.scope.exerciseRef?.value,
        'p_note_type': command.scope.type.value,
        'p_body': command.body,
        'p_expected_revision': null,
        'p_mutation_id': command.mutationId,
      };

  Map<String, dynamic> _updateParams(RoutineNoteUpdate command) => {
        'p_operation': 'update',
        'p_note_id': command.id,
        'p_routine_id': null,
        'p_exercise_ref': null,
        'p_note_type': null,
        'p_body': command.body,
        'p_expected_revision': command.expectedRevision,
        'p_mutation_id': command.mutationId,
      };

  Map<String, dynamic> _transferParams(RoutineNoteTransfer command) => {
        'p_operation': 'transfer',
        'p_note_id': command.id,
        'p_routine_id': command.destination.routineId?.value,
        'p_exercise_ref': command.destination.exerciseRef?.value,
        'p_note_type': command.destination.type.value,
        'p_body': null,
        'p_expected_revision': command.expectedRevision,
        'p_mutation_id': command.mutationId,
      };

  Map<String, dynamic> _deleteParams(RoutineNoteDelete command) => {
        'p_operation': 'delete',
        'p_note_id': command.id,
        'p_routine_id': null,
        'p_exercise_ref': null,
        'p_note_type': null,
        'p_body': null,
        'p_expected_revision': command.expectedRevision,
        'p_mutation_id': command.mutationId,
      };

  RoutineNote _noteResult(Map<String, dynamic> result) {
    if (result['status'] == 'expired') {
      throw const RoutineNoteException(RoutineNoteFailureKind.expired);
    }
    if (result['status'] != 'applied' || result['note'] is! Map) {
      throw const RoutineNoteException(RoutineNoteFailureKind.malformedData);
    }
    try {
      return RoutineNote.fromJson(
        Map<String, dynamic>.from(result['note'] as Map),
      );
    } on FormatException {
      throw const RoutineNoteException(RoutineNoteFailureKind.malformedData);
    } on ArgumentError {
      throw const RoutineNoteException(RoutineNoteFailureKind.malformedData);
    }
  }

  String _owner() {
    final owner = _currentUserId()?.trim().toLowerCase();
    if (owner == null || !_isUuid(owner)) {
      throw const RoutineNoteException(RoutineNoteFailureKind.unauthorized);
    }
    return owner;
  }

  void _checkOwner(String owner, {String mutationId = 'session-changed'}) {
    if (!_sameOwner(owner)) {
      throw RoutineNoteOutcomeUnknown(
        mutationId: mutationId,
        reason: RoutineNoteUncertainty.sessionChanged,
      );
    }
  }

  bool _sameOwner(String owner) =>
      _currentUserId()?.trim().toLowerCase() == owner;

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      ).hasMatch(value);

  static RoutineNoteFailureKind? _definite(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('quota_exceeded')) {
      return RoutineNoteFailureKind.quotaExceeded;
    }
    if (message.contains('revision_conflict')) {
      return RoutineNoteFailureKind.revisionConflict;
    }
    if (message.contains('mutation_conflict') ||
        message.contains('id_conflict')) {
      return RoutineNoteFailureKind.mutationConflict;
    }
    if (message.contains('not_found') || message.contains('not found')) {
      return RoutineNoteFailureKind.notFound;
    }
    if (message.contains('archived') || message.contains('invalid_')) {
      return RoutineNoteFailureKind.invalidRequest;
    }
    final status = int.tryParse(error.code ?? '');
    if (error.code?.startsWith('08') == true ||
        error.code == '408' ||
        error.code == '499' ||
        (status != null && status >= 500 && status <= 599)) {
      return null;
    }
    return switch (error.code) {
      '28000' ||
      '28P01' ||
      '401' ||
      'PGRST301' ||
      'PGRST302' ||
      'PGRST303' =>
        RoutineNoteFailureKind.unauthorized,
      '42501' || '403' => RoutineNoteFailureKind.forbidden,
      '22023' || '23503' || '23514' => RoutineNoteFailureKind.invalidRequest,
      'P0002' => RoutineNoteFailureKind.notFound,
      'PGRST202' || 'PGRST203' => RoutineNoteFailureKind.unavailable,
      _ => RoutineNoteFailureKind.unavailable,
    };
  }
}

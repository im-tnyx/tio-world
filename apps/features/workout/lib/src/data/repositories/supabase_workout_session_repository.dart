import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/models/workout_session_record.dart';
import '../../domain/repositories/workout_session_repository.dart';
import '../dto/workout_session_dtos.dart';
import 'supabase_workout_session_gateway.dart';

/// Production implementation of [WorkoutSessionRepository] backed by Supabase.
///
/// Strictly online-first: no local mutation queues, no silent in-memory fallbacks.
/// Adheres to optimistic concurrency control (OCC), bracketed read consistency,
/// and deterministic set slot ordering.
final class SupabaseWorkoutSessionRepository
    implements WorkoutSessionRepository {
  SupabaseWorkoutSessionRepository({
    required WorkoutSessionGateway gateway,
    required String? Function() currentUserId,
    Duration requestTimeout = const Duration(seconds: 15),
    int readAttempts = 3,
  })  : _gateway = gateway,
        _currentUserId = currentUserId,
        _requestTimeout = requestTimeout,
        _readAttempts = readAttempts {
    if (requestTimeout <= Duration.zero) {
      throw ArgumentError.value(
        requestTimeout,
        'requestTimeout',
        'must be positive',
      );
    }
    if (readAttempts < 1) {
      throw ArgumentError.value(
        readAttempts,
        'readAttempts',
        'must be at least 1',
      );
    }
  }

  factory SupabaseWorkoutSessionRepository.fromClient({
    required SupabaseClient client,
    Duration requestTimeout = const Duration(seconds: 15),
    int readAttempts = 3,
  }) =>
      SupabaseWorkoutSessionRepository(
        gateway: SupabaseWorkoutSessionGateway(client),
        currentUserId: () => client.auth.currentUser?.id,
        requestTimeout: requestTimeout,
        readAttempts: readAttempts,
      );

  final WorkoutSessionGateway _gateway;
  final String? Function() _currentUserId;
  final Duration _requestTimeout;
  final int _readAttempts;

  @override
  Future<WorkoutSessionRecord?> getActiveSession() async {
    final owner = _owner();
    final header = await _executeRead(
      owner,
      () => _gateway.readActiveSessionHeader(owner),
    );

    if (header == null) return null;
    final sessionId = WorkoutSessionId(header['id'] as String);
    final sessionRecord = await _readSession(owner, sessionId);
    if (sessionRecord == null) return null;
    if (sessionRecord.session.status != WorkoutSessionStatus.active &&
        sessionRecord.session.status != WorkoutSessionStatus.paused) {
      return null;
    }
    return sessionRecord;
  }

  @override
  Future<WorkoutSessionRecord?> getSession(WorkoutSessionId sessionId) async {
    final owner = _owner();
    return _readSession(owner, sessionId);
  }

  @override
  Future<WorkoutSessionRecord> startSession(WorkoutSession session) async {
    final owner = _owner();
    if (session.userId.toLowerCase() != owner) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.unauthorized,
        message: 'Cannot start session for a different user ID',
      );
    }

    final snapshotJson = WorkoutSessionSnapshotDto.toJson(session.snapshot);
    final params = <String, dynamic>{
      'p_session_id': session.id.value,
      'p_program_id': session.programId.value,
      'p_routine_id': session.routineId.value,
      'p_started_at_utc': session.time.startedAtUtc.toUtc().toIso8601String(),
      'p_local_date': session.localDate,
      'p_routine_snapshot': snapshotJson,
    };

    final row = await _executeMutation(
      owner: owner,
      sessionId: session.id,
      operation: () => _gateway.rpcStartWorkoutSession(params),
    );

    final rowDto = WorkoutSessionRowDto.fromJson(row);

    // If an idempotent replay occurred on a session that already has performed sets,
    // fetch the full session with sets. Otherwise return new empty record.
    if (rowDto.revision > 1) {
      final existingRecord = await _readSession(owner, session.id);
      if (existingRecord != null) return existingRecord;
    }

    return rowDto.toRecord(
      performedSets: const [],
      snapshotOverride: session.snapshot,
    );
  }

  @override
  Future<WorkoutSessionRecord> pauseSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime pausedAtUtc,
  }) async {
    final owner = _owner();
    final params = <String, dynamic>{
      'p_session_id': sessionId.value,
      'p_expected_revision': expectedRevision,
      'p_paused_at_utc': pausedAtUtc.toUtc().toIso8601String(),
    };

    await _executeMutation(
      owner: owner,
      sessionId: sessionId,
      operation: () => _gateway.rpcPauseWorkoutSession(params),
    );

    final record = await _readSession(owner, sessionId);
    if (record == null) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.notFound,
        message: 'Session not found after pause transition',
      );
    }
    return record;
  }

  @override
  Future<WorkoutSessionRecord> resumeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime resumedAtUtc,
  }) async {
    final owner = _owner();
    final params = <String, dynamic>{
      'p_session_id': sessionId.value,
      'p_expected_revision': expectedRevision,
      'p_resumed_at_utc': resumedAtUtc.toUtc().toIso8601String(),
    };

    await _executeMutation(
      owner: owner,
      sessionId: sessionId,
      operation: () => _gateway.rpcResumeWorkoutSession(params),
    );

    final record = await _readSession(owner, sessionId);
    if (record == null) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.notFound,
        message: 'Session not found after resume transition',
      );
    }
    return record;
  }

  @override
  Future<WorkoutSessionRecord> logPerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required PerformedSet set,
  }) async {
    final owner = _owner();
    final params = WorkoutPerformedSetRowDto.toRpcParams(
      sessionId: sessionId.value,
      expectedRevision: expectedRevision,
      set: set,
    );

    await _executeMutation(
      owner: owner,
      sessionId: sessionId,
      operation: () => _gateway.rpcLogWorkoutPerformedSet(params),
    );

    // rpc_log_workout_performed_set returns the child set row, not the parent session.
    // Read back the authoritative parent session to capture authoritative revision
    // and full performed-set list.
    final record = await _readSession(owner, sessionId);
    if (record == null) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.notFound,
        message: 'Session not found after logging set',
      );
    }
    return record;
  }

  @override
  Future<WorkoutSessionRecord> removePerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required String setId,
  }) async {
    final owner = _owner();
    final params = <String, dynamic>{
      'p_set_id': setId,
      'p_session_id': sessionId.value,
      'p_expected_session_revision': expectedRevision,
    };

    await _executeMutation(
      owner: owner,
      sessionId: sessionId,
      operation: () => _gateway.rpcRemoveWorkoutPerformedSet(params),
    );

    // Read back authoritative session after set removal.
    final record = await _readSession(owner, sessionId);
    if (record == null) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.notFound,
        message: 'Session not found after removing set',
      );
    }
    return record;
  }

  @override
  Future<WorkoutSessionRecord> completeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime completedAtUtc,
    String? notes,
  }) async {
    final owner = _owner();
    final params = <String, dynamic>{
      'p_session_id': sessionId.value,
      'p_expected_revision': expectedRevision,
      'p_completed_at_utc': completedAtUtc.toUtc().toIso8601String(),
      'p_notes': notes,
    };

    await _executeMutation(
      owner: owner,
      sessionId: sessionId,
      operation: () => _gateway.rpcCompleteWorkoutSession(params),
    );

    final record = await _readSession(owner, sessionId);
    if (record == null) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.notFound,
        message: 'Session not found after completion',
      );
    }
    return record;
  }

  @override
  Future<WorkoutSessionRecord> discardSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime discardedAtUtc,
    required String reason,
  }) async {
    final owner = _owner();
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.invalidPayload,
        message: 'Discard reason must contain non-whitespace text',
      );
    }

    final params = <String, dynamic>{
      'p_session_id': sessionId.value,
      'p_expected_revision': expectedRevision,
      'p_discarded_at_utc': discardedAtUtc.toUtc().toIso8601String(),
      'p_discard_reason': trimmedReason,
    };

    await _executeMutation(
      owner: owner,
      sessionId: sessionId,
      operation: () => _gateway.rpcDiscardWorkoutSession(params),
    );

    final record = await _readSession(owner, sessionId);
    if (record == null) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.notFound,
        message: 'Session not found after discard',
      );
    }
    return record;
  }

  /// Bracketed consistency read: verifies session header revision before and after
  /// reading child sets to guarantee deterministic, un-skewed snapshot reading.
  Future<WorkoutSessionRecord?> _readSession(
    String owner,
    WorkoutSessionId sessionId,
  ) async {
    for (var attempt = 0; attempt < _readAttempts; attempt++) {
      final startHeader = await _executeRead(
        owner,
        () => _gateway.readSessionHeader(owner, sessionId.value),
      );
      if (startHeader == null) return null;

      final startDto = WorkoutSessionRowDto.fromJson(startHeader);

      final setRows = await _executeRead(
        owner,
        () => _gateway.readPerformedSets(owner, sessionId.value),
      );

      final endHeader = await _executeRead(
        owner,
        () => _gateway.readSessionHeader(owner, sessionId.value),
      );
      if (endHeader == null) return null;

      final endDto = WorkoutSessionRowDto.fromJson(endHeader);

      // Verify that revision did not change during reading of performed sets
      if (startDto.revision != endDto.revision) {
        continue;
      }

      final performedSets = setRows
          .map(WorkoutPerformedSetRowDto.fromJson)
          .map((dto) => dto.toDomain())
          .toList(growable: false);

      _checkOwner(owner);
      return endDto.toRecord(performedSets: performedSets);
    }

    throw const WorkoutSessionPersistenceException(
      WorkoutSessionPersistenceFailureKind.readConflict,
      message:
          'Sustained write contention prevented acquiring a consistent session snapshot',
    );
  }

  Future<T> _executeRead<T>(
    String owner,
    Future<T> Function() call,
  ) async {
    _checkOwner(owner);
    try {
      final result = await call().timeout(_requestTimeout);
      _checkOwner(owner);
      return result;
    } on WorkoutSessionPersistenceException {
      rethrow;
    } on TimeoutException catch (e) {
      throw WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'Read request timed out: $e',
        cause: e,
      );
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      throw WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'Network transport failure: $e',
        cause: e,
      );
    }
  }

  Future<T> _executeMutation<T>({
    required String owner,
    required WorkoutSessionId sessionId,
    required Future<T> Function() operation,
  }) async {
    _checkOwner(owner);
    try {
      final result = await operation().timeout(_requestTimeout);
      _checkOwner(owner);
      return result;
    } on WorkoutSessionPersistenceException catch (e) {
      if (e.kind == WorkoutSessionPersistenceFailureKind.unauthenticated ||
          e.kind == WorkoutSessionPersistenceFailureKind.unauthorized) {
        throw WorkoutSessionMutationOutcomeUnknown(
          sessionId: sessionId,
          reason: WorkoutSessionMutationUncertainty.sessionChanged,
          cause: e,
        );
      }
      rethrow;
    } on TimeoutException catch (e) {
      throw WorkoutSessionMutationOutcomeUnknown(
        sessionId: sessionId,
        reason: WorkoutSessionMutationUncertainty.networkTimeout,
        cause: e,
      );
    } on PostgrestException catch (e) {
      throw _mapPostgrestException(e);
    } catch (e) {
      throw WorkoutSessionMutationOutcomeUnknown(
        sessionId: sessionId,
        reason: WorkoutSessionMutationUncertainty.connectionError,
        cause: e,
      );
    }
  }

  String _owner() {
    final owner = _currentUserId()?.trim().toLowerCase();
    if (owner == null || !_isUuid(owner)) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.unauthenticated,
        message: 'No authenticated user session',
      );
    }
    return owner;
  }

  void _checkOwner(String owner) {
    final current = _currentUserId()?.trim().toLowerCase();
    if (current == null || !_isUuid(current)) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.unauthenticated,
        message: 'No authenticated user session',
      );
    }
    if (current != owner) {
      throw const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.unauthorized,
        message: 'Active authentication session changed during operation',
      );
    }
  }

  static bool _isUuid(String value) => RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      ).hasMatch(value);

  static WorkoutSessionPersistenceException _mapPostgrestException(
    PostgrestException error,
  ) {
    final code = error.code ?? '';
    final message = (error.message).toLowerCase();
    final details = (error.details?.toString() ?? '').toLowerCase();

    if (code == '28000' ||
        code == '28P01' ||
        code == '401' ||
        code == 'PGRST301' ||
        code == 'PGRST302' ||
        code == 'PGRST303' ||
        message.contains('not_authenticated')) {
      return WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.unauthenticated,
        message: error.message,
        cause: error,
      );
    }

    if (code == '42501' ||
        code == '403' ||
        message.contains('ownership_mismatch') ||
        message.contains('unauthorized')) {
      return WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.unauthorized,
        message: error.message,
        cause: error,
      );
    }

    if (code == 'P0003' || message.contains('stale_revision_conflict')) {
      return WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.staleRevisionConflict,
        message: error.message,
        cause: error,
      );
    }

    if (code == 'P0001' ||
        message.contains('session_already_terminal') ||
        message.contains('terminal_workout_session_immutable') ||
        message.contains('terminal_session_sets_immutable') ||
        message.contains('immutable')) {
      return WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.terminalSessionImmutable,
        message: error.message,
        cause: error,
      );
    }

    if (code == 'P0002' ||
        message.contains('session_not_found') ||
        message.contains('set_not_found')) {
      return WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.notFound,
        message: error.message,
        cause: error,
      );
    }

    if (code == '23505' || message.contains('duplicate')) {
      if (message.contains('uq_user_workout_performed_sets_slot') ||
          details.contains('uq_user_workout_performed_sets_slot')) {
        return WorkoutSessionPersistenceException(
          WorkoutSessionPersistenceFailureKind.setSlotConflict,
          message: error.message,
          cause: error,
        );
      }
      if (message.contains('single_active') ||
          details.contains('single_active') ||
          message.contains('uq_user_workout_sessions_single_active') ||
          details.contains('uq_user_workout_sessions_single_active')) {
        return WorkoutSessionPersistenceException(
          WorkoutSessionPersistenceFailureKind.duplicateActiveSession,
          message: error.message,
          cause: error,
        );
      }
      if (message.contains('duplicate_session_conflict')) {
        return WorkoutSessionPersistenceException(
          WorkoutSessionPersistenceFailureKind.duplicateSessionConflict,
          message: error.message,
          cause: error,
        );
      }
      if (message.contains('terminal_payload_conflict')) {
        return WorkoutSessionPersistenceException(
          WorkoutSessionPersistenceFailureKind.terminalPayloadConflict,
          message: error.message,
          cause: error,
        );
      }
      return WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.invalidPayload,
        message: error.message,
        cause: error,
      );
    }

    if (code == '22023' || code == '23514' || code == '23503') {
      if (message.contains('limit_exceeded') ||
          message.contains('session_performed_sets_limit_exceeded')) {
        return WorkoutSessionPersistenceException(
          WorkoutSessionPersistenceFailureKind.quotaExceeded,
          message: error.message,
          cause: error,
        );
      }
      return WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.invalidPayload,
        message: error.message,
        cause: error,
      );
    }

    if (code.startsWith('08') ||
        code == '408' ||
        code == '499' ||
        code == 'PGRST202' ||
        code == 'PGRST203') {
      return WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.unavailable,
        message: error.message,
        cause: error,
      );
    }

    return WorkoutSessionPersistenceException(
      WorkoutSessionPersistenceFailureKind.unavailable,
      message: error.message,
      cause: error,
    );
  }
}

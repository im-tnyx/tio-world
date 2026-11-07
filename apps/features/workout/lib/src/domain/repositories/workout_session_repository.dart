import 'package:tio_shared/shared.dart';

import '../models/workout_session_record.dart';

/// Categories of persistence failures when interacting with the Workout Session gateway.
enum WorkoutSessionPersistenceFailureKind {
  /// The user is not authenticated with the backend (PostgreSQL 28000 / HTTP 401).
  unauthenticated,

  /// The user does not have permission to access or mutate this session or set (PostgreSQL 42501 / HTTP 403).
  unauthorized,

  /// The target session or set does not exist (PostgreSQL P0002).
  notFound,

  /// The provided expected revision does not match the server revision (PostgreSQL P0003 OCC conflict).
  staleRevisionConflict,

  /// The user already has an active or paused session (violates partial unique index).
  duplicateActiveSession,

  /// A performed set slot is already occupied by a different set (violates uq_user_workout_performed_sets_slot, PostgreSQL 23505).
  setSlotConflict,

  /// An idempotent start replay was attempted with conflicting parameters (PostgreSQL 23505).
  duplicateSessionConflict,

  /// A terminal replay was attempted with conflicting notes or discard reason (PostgreSQL 23505).
  terminalPayloadConflict,

  /// A completed or discarded session cannot be modified (PostgreSQL P0001).
  terminalSessionImmutable,

  /// The session is in an incompatible lifecycle status for the requested transition
  /// (e.g. attempting to pause an already paused session, or resume an active session;
  /// PostgreSQL P0001 invalid_transition_from_status).
  invalidStateTransition,

  /// The mutation was acknowledged/committed by the server, but the subsequent
  /// readback to fetch the authoritative record failed (e.g. read timeout or conflict).
  ///
  /// Callers must NOT replay the mutation with stale revision; they should reconcile
  /// state via [WorkoutSessionRepository.getSession] or [WorkoutSessionRepository.getActiveSession].
  mutationCommittedReadbackFailed,

  /// The session performed sets quota (500 sets) has been exceeded (PostgreSQL 22023).
  quotaExceeded,

  /// The request payload or timestamp was invalid (PostgreSQL 22023).
  invalidPayload,

  /// Sustained read contention prevented acquiring a consistent revision snapshot.
  readConflict,

  /// Network transport error or DNS failure before a connection could be established.
  networkUnavailable,

  /// Server unavailable or temporary infrastructure failure.
  unavailable,
}

/// Typed exception for workout session persistence failures.
///
/// Contains a sanitized [kind] and does not leak private user workout data or tokens.
final class WorkoutSessionPersistenceException implements Exception {
  const WorkoutSessionPersistenceException(
    this.kind, {
    this.message,
    this.cause,
  });

  final WorkoutSessionPersistenceFailureKind kind;
  final String? message;
  final Object? cause;

  @override
  String toString() {
    final msg = message != null ? ': $message' : '';
    return 'WorkoutSessionPersistenceException(${kind.name}$msg)';
  }
}

/// Thrown when a mutation was acknowledged and applied by the server, but the subsequent
/// readback to construct the authoritative session record failed (e.g., read timeout,
/// transport drop, or read contention).
///
/// Because the write succeeded on the server, the server revision was bumped. Callers
/// MUST NOT replay the mutation with the original expected revision; instead, callers
/// should reconcile state using [WorkoutSessionRepository.getSession] or
/// [WorkoutSessionRepository.getActiveSession].
final class WorkoutSessionCommittedReadbackException
    extends WorkoutSessionPersistenceException {
  WorkoutSessionCommittedReadbackException({
    required this.sessionId,
    required this.operationName,
    super.cause,
    String? message,
  }) : super(
          WorkoutSessionPersistenceFailureKind.mutationCommittedReadbackFailed,
          message: message ??
              'Committed $operationName acknowledged by server, but readback failed for session ${sessionId.value}',
        );

  final WorkoutSessionId sessionId;
  final String operationName;

  @override
  String toString() =>
      'WorkoutSessionCommittedReadbackException(sessionId: ${sessionId.value}, operation: $operationName, message: $message)';
}

/// Reasons why a mutation outcome could not be definitely confirmed.
enum WorkoutSessionMutationUncertainty {
  /// The network request timed out while in flight; it may or may not have committed.
  networkTimeout,

  /// The network connection dropped after dispatch; server state is unconfirmed.
  connectionError,

  /// The active authenticated user session changed while the mutation was in-flight.
  sessionChanged,
}

/// Thrown when a mutation request was dispatched but the client could not confirm
/// whether the server applied or aborted the transaction.
///
/// Callers must preserve recoverable input in memory and reconcile against server
/// state rather than blindly retrying or reporting success.
final class WorkoutSessionMutationOutcomeUnknown implements Exception {
  const WorkoutSessionMutationOutcomeUnknown({
    required this.sessionId,
    required this.reason,
    this.cause,
  });

  final WorkoutSessionId sessionId;
  final WorkoutSessionMutationUncertainty reason;
  final Object? cause;

  @override
  String toString() =>
      'WorkoutSessionMutationOutcomeUnknown(sessionId: ${sessionId.value}, reason: ${reason.name})';
}

/// Authoritative contract for persisting and restoring workout sessions and performed sets.
abstract interface class WorkoutSessionRepository {
  /// Reads the single active or paused session for the authenticated user,
  /// including all performed sets, or returns `null` if none exists.
  ///
  /// Uses bracketed consistency reads to prevent silent missing or duplicated
  /// sets under concurrent mutation.
  Future<WorkoutSessionRecord?> getActiveSession();

  /// Reads a specific session by its [sessionId], including all performed sets,
  /// or returns `null` if not found or belongs to another user.
  ///
  /// Uses bracketed consistency reads to prevent silent missing or duplicated
  /// sets under concurrent mutation.
  Future<WorkoutSessionRecord?> getSession(WorkoutSessionId sessionId);

  /// Starts a new active workout session by invoking `rpc_start_workout_session`.
  ///
  /// Returns the authoritative [WorkoutSessionRecord] (revision 1 on initial start,
  /// or current revision on idempotent replay).
  Future<WorkoutSessionRecord> startSession(WorkoutSession session);

  /// Pauses an active workout session by invoking `rpc_pause_workout_session`.
  ///
  /// Requires [expectedRevision] for optimistic concurrency control.
  Future<WorkoutSessionRecord> pauseSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime pausedAtUtc,
  });

  /// Resumes a paused workout session by invoking `rpc_resume_workout_session`.
  ///
  /// Requires [expectedRevision] for optimistic concurrency control.
  Future<WorkoutSessionRecord> resumeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime resumedAtUtc,
  });

  /// Logs or updates a performed set by invoking `rpc_log_workout_performed_set`.
  ///
  /// Requires [expectedRevision] of the parent session for optimistic concurrency control.
  /// Performs an owner-scoped readback to return the authoritative [WorkoutSessionRecord]
  /// with server revision and updated sets.
  Future<WorkoutSessionRecord> logPerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required PerformedSet set,
  });

  /// Removes a performed set by invoking `rpc_remove_workout_performed_set`.
  ///
  /// Requires [expectedRevision] of the parent session for optimistic concurrency control.
  /// Performs an owner-scoped readback to return the authoritative [WorkoutSessionRecord]
  /// with updated server revision and remaining sets.
  Future<WorkoutSessionRecord> removePerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required String setId,
  });

  /// Completes a workout session by invoking `rpc_complete_workout_session`.
  ///
  /// Requires [expectedRevision] for optimistic concurrency control.
  Future<WorkoutSessionRecord> completeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime completedAtUtc,
    String? notes,
  });

  /// Discards a workout session by invoking `rpc_discard_workout_session`.
  ///
  /// Requires [expectedRevision] for optimistic concurrency control and non-blank [reason].
  Future<WorkoutSessionRecord> discardSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime discardedAtUtc,
    required String reason,
  });
}

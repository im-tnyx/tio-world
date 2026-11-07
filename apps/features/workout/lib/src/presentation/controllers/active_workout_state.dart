import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/models/workout_session_record.dart';

/// Lifecycle statuses for the Active Workout presentation controller.
enum ActiveWorkoutStatus {
  /// Initial uninitialized state before checking for an active session.
  initial,

  /// Checking the persistence gateway for an active or paused session.
  restoring,

  /// Verified that no active or paused workout session exists.
  noSession,

  /// A workout session is actively running.
  active,

  /// A workout session is currently paused.
  paused,

  /// A mutation succeeded or was sent, but authoritative readback failed or
  /// network dropped; requires state reconciliation before further mutations.
  reconciliationRequired,

  /// The workout session reached terminal completed status.
  completed,

  /// The workout session reached terminal discarded status.
  discarded,

  /// The active user logged out or switched accounts; in-memory data is invalidated.
  authInvalidated,
}

/// In-memory rest timer state between performed sets.
///
/// Purely derived from timestamps; does not tick or persist into the database.
@immutable
final class ActiveRestTimerState {
  const ActiveRestTimerState({
    required this.targetInstantUtc,
    required this.totalDurationSeconds,
    this.sessionExerciseIndex,
    this.setIndex,
  }) : assert(totalDurationSeconds > 0, 'totalDurationSeconds must be positive');

  /// The instant when this rest period ends.
  final DateTime targetInstantUtc;

  /// The configured total rest duration in seconds.
  final int totalDurationSeconds;

  /// The 0-based session exercise occurrence index this rest followed.
  final int? sessionExerciseIndex;

  /// The 0-based set index this rest followed.
  final int? setIndex;

  /// Calculates the remaining rest duration relative to [nowUtc].
  ///
  /// Returns [Duration.zero] if [nowUtc] has reached or passed [targetInstantUtc].
  Duration remainingDuration(DateTime nowUtc) {
    final now = nowUtc.isUtc ? nowUtc : nowUtc.toUtc();
    final diff = targetInstantUtc.difference(now);
    return diff.isNegative ? Duration.zero : diff;
  }

  /// Whether the rest timer has elapsed relative to [nowUtc].
  bool isExpired(DateTime nowUtc) {
    final now = nowUtc.isUtc ? nowUtc : nowUtc.toUtc();
    return now.isAfter(targetInstantUtc) || now.isAtSameMomentAs(targetInstantUtc);
  }

  /// Returns a new rest timer state with [seconds] added to the target instant.
  ActiveRestTimerState addSeconds(int seconds) => ActiveRestTimerState(
        targetInstantUtc: targetInstantUtc.add(Duration(seconds: seconds)),
        totalDurationSeconds: totalDurationSeconds + seconds,
        sessionExerciseIndex: sessionExerciseIndex,
        setIndex: setIndex,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveRestTimerState &&
          other.targetInstantUtc == targetInstantUtc &&
          other.totalDurationSeconds == totalDurationSeconds &&
          other.sessionExerciseIndex == sessionExerciseIndex &&
          other.setIndex == setIndex;

  @override
  int get hashCode => Object.hash(
        targetInstantUtc,
        totalDurationSeconds,
        sessionExerciseIndex,
        setIndex,
      );

  @override
  String toString() =>
      'ActiveRestTimerState(target: $targetInstantUtc, total: ${totalDurationSeconds}s)';
}

/// Immutable state rendered by the Active Workout presentation controller.
@immutable
final class ActiveWorkoutState {
  const ActiveWorkoutState({
    this.status = ActiveWorkoutStatus.initial,
    this.record,
    this.activeElapsedDuration = Duration.zero,
    this.activeRestTimer,
    this.isActionPending = false,
    this.pendingActionName,
    this.reconciliationReason,
    this.errorMessage,
    this.lastKnownSessionId,
  });

  /// Factory for initial state.
  const ActiveWorkoutState.initial() : this(status: ActiveWorkoutStatus.initial);

  /// Factory for restoring state.
  const ActiveWorkoutState.restoring()
      : this(status: ActiveWorkoutStatus.restoring);

  /// Factory when no session exists.
  const ActiveWorkoutState.noSession()
      : this(status: ActiveWorkoutStatus.noSession);

  /// Factory for an invalidated auth session.
  const ActiveWorkoutState.authInvalidated()
      : this(status: ActiveWorkoutStatus.authInvalidated);

  /// Current primary lifecycle status.
  final ActiveWorkoutStatus status;

  /// Authoritative server record containing the pure-Dart [WorkoutSession] and [revision].
  final WorkoutSessionRecord? record;

  /// Active workout elapsed duration (excluding pauses).
  final Duration activeElapsedDuration;

  /// Active rest countdown state, if currently resting.
  final ActiveRestTimerState? activeRestTimer;

  /// Whether an asynchronous session mutation is currently in-flight.
  final bool isActionPending;

  /// Human-readable identifier of the currently pending mutation action.
  final String? pendingActionName;

  /// Explicit reason why state reconciliation is required.
  final String? reconciliationReason;

  /// Transient or recoverable error message.
  final String? errorMessage;

  /// The most recent session ID observed by the controller.
  final WorkoutSessionId? lastKnownSessionId;

  /// Whether the session is actively running (active or paused).
  bool get isRunning =>
      status == ActiveWorkoutStatus.active ||
      status == ActiveWorkoutStatus.paused;

  /// Whether the session is currently paused.
  bool get isPaused => status == ActiveWorkoutStatus.paused;

  /// Whether the session has ended in a terminal state.
  bool get isTerminal =>
      status == ActiveWorkoutStatus.completed ||
      status == ActiveWorkoutStatus.discarded;

  /// Convenience accessor for the underlying [WorkoutSession].
  WorkoutSession? get session => record?.session;

  /// Authoritative server revision number.
  int? get revision => record?.revision;

  /// Active or last-known session ID.
  ///
  /// Prioritizes [lastKnownSessionId] (e.g. the explicit target of a pending
  /// or uncertain mutation) so a stale previous session record cannot hijack
  /// reconciliation of a new session.
  WorkoutSessionId? get sessionId =>
      lastKnownSessionId ?? record?.session.id;

  /// Sets performed in this session so far.
  List<PerformedSet> get performedSets =>
      record?.session.performedSets ?? const [];

  /// Frozen routine snapshot captured at start time.
  WorkoutSessionSnapshot? get snapshot => record?.session.snapshot;

  /// Creates a copy of this state with replaced fields.
  ActiveWorkoutState copyWith({
    ActiveWorkoutStatus? status,
    WorkoutSessionRecord? record,
    bool clearRecord = false,
    Duration? activeElapsedDuration,
    ActiveRestTimerState? activeRestTimer,
    bool clearRestTimer = false,
    bool? isActionPending,
    String? pendingActionName,
    bool clearPendingAction = false,
    String? reconciliationReason,
    bool clearReconciliationReason = false,
    String? errorMessage,
    bool clearErrorMessage = false,
    WorkoutSessionId? lastKnownSessionId,
  }) =>
      ActiveWorkoutState(
        status: status ?? this.status,
        record: clearRecord ? null : (record ?? this.record),
        activeElapsedDuration:
            activeElapsedDuration ?? this.activeElapsedDuration,
        activeRestTimer: clearRestTimer
            ? null
            : (activeRestTimer ?? this.activeRestTimer),
        isActionPending: isActionPending ?? this.isActionPending,
        pendingActionName: clearPendingAction
            ? null
            : (pendingActionName ?? this.pendingActionName),
        reconciliationReason: clearReconciliationReason
            ? null
            : (reconciliationReason ?? this.reconciliationReason),
        errorMessage:
            clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
        lastKnownSessionId:
            lastKnownSessionId ?? this.lastKnownSessionId ?? record?.session.id,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActiveWorkoutState &&
          other.status == status &&
          other.record == record &&
          other.activeElapsedDuration == activeElapsedDuration &&
          other.activeRestTimer == activeRestTimer &&
          other.isActionPending == isActionPending &&
          other.pendingActionName == pendingActionName &&
          other.reconciliationReason == reconciliationReason &&
          other.errorMessage == errorMessage &&
          other.lastKnownSessionId == lastKnownSessionId;

  @override
  int get hashCode => Object.hash(
        status,
        record,
        activeElapsedDuration,
        activeRestTimer,
        isActionPending,
        pendingActionName,
        reconciliationReason,
        errorMessage,
        lastKnownSessionId,
      );

  @override
  String toString() =>
      'ActiveWorkoutState(status: ${status.name}, sessionId: ${sessionId?.value}, '
      'rev: $revision, activeTime: ${activeElapsedDuration.inSeconds}s, '
      'pending: $isActionPending)';
}

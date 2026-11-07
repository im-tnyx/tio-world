import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

import '../../domain/models/workout_execution_readiness.dart';
import '../../domain/models/workout_session_record.dart';
import '../../domain/repositories/workout_session_repository.dart';
import 'active_workout_state.dart';

/// Presentation controller orchestrating live workout sessions, set logging,
/// pause/resume, timing derivations, and recovery.
///
/// Adheres strictly to the single-active-session invariant, optimistic concurrency
/// control (OCC), and authentication lifecycle safety.
final class ActiveWorkoutController extends ChangeNotifier {
  ActiveWorkoutController({
    required WorkoutSessionRepository repository,
    required String? Function() currentUserId,
    DateTime Function()? clock,
    String Function()? uuidGenerator,
  })  : _repository = repository,
        _currentUserId = currentUserId,
        _clock = clock ?? DateTime.timestamp,
        _uuidGenerator = uuidGenerator ?? (() => const Uuid().v4()),
        _initialOwnerId = currentUserId() {
    _state = const ActiveWorkoutState.initial();
  }

  final WorkoutSessionRepository _repository;
  final String? Function() _currentUserId;
  final DateTime Function() _clock;
  final String Function() _uuidGenerator;
  final String? _initialOwnerId;

  ActiveWorkoutState _state = const ActiveWorkoutState.initial();
  ActiveWorkoutState get state => _state;

  var _version = 0;
  var _disposed = false;
  var _isActionInFlight = false;
  Timer? _durationTicker;

  DateTime _nowUtc() => _clock().toUtc();

  /// Calculates elapsed active workout duration safely.
  ///
  /// Protects against clock rollbacks where device time jumps before the session's
  /// [lastTransitionAtUtc], preventing uncaught [ArgumentError] exceptions from
  /// domain timing validation while keeping displayed duration stable and non-negative.
  /// Calculates elapsed active workout duration safely.
  ///
  /// Protects against clock rollbacks where device time jumps before the session's
  /// [lastTransitionAtUtc], preventing uncaught [ArgumentError] exceptions from
  /// domain timing validation while keeping displayed duration stable and non-negative.
  ///
  /// When [enforceMonotonic] is true (used by periodic UI ticker updates), the duration
  /// will not regress below previously displayed [state.activeElapsedDuration] for the
  /// same session. When false (used when adopting authoritative server records), the
  /// authoritative server-derived duration (e.g. at pause or completion) is allowed
  /// to correct any speculative ticker drift that accumulated during network latency.
  Duration _calculateElapsedDuration(
    WorkoutSession session,
    DateTime now, {
    bool enforceMonotonic = false,
  }) {
    final transitionAt = session.time.lastTransitionAtUtc;
    final evaluationInstant = now.isBefore(transitionAt) ? transitionAt : now;
    final isSameSession =
        state.record != null && state.record!.session.id == session.id;
    try {
      final computed = session.time.elapsedActiveDuration(evaluationInstant);
      if (enforceMonotonic &&
          isSameSession &&
          computed < state.activeElapsedDuration) {
        return state.activeElapsedDuration;
      }
      return computed;
    } catch (_) {
      return (enforceMonotonic && isSameSession)
          ? state.activeElapsedDuration
          : Duration.zero;
    }
  }

  bool _isAuthInvalid() {
    final liveId = _currentUserId();
    return liveId == null || liveId != _initialOwnerId;
  }

  void _emit(ActiveWorkoutState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  /// Adopts the authoritative server record and derives presentation status.
  void _applyAuthoritativeRecord(
    WorkoutSessionRecord record, {
    ActiveRestTimerState? restTimer,
    bool clearRestTimer = false,
  }) {
    final session = record.session;
    final elapsed = _calculateElapsedDuration(
      session,
      _nowUtc(),
      enforceMonotonic: false,
    );
    final status = switch (session.status) {
      WorkoutSessionStatus.active => ActiveWorkoutStatus.active,
      WorkoutSessionStatus.paused => ActiveWorkoutStatus.paused,
      WorkoutSessionStatus.completed => ActiveWorkoutStatus.completed,
      WorkoutSessionStatus.discarded => ActiveWorkoutStatus.discarded,
    };

    if (session.isTerminal) {
      stopDurationTicker();
    }

    _emit(ActiveWorkoutState(
      status: status,
      record: record,
      activeElapsedDuration: elapsed,
      activeRestTimer:
          (clearRestTimer || session.isTerminal) ? null : (restTimer ?? state.activeRestTimer),
      lastKnownSessionId: session.id,
    ));
  }

  /// Restores any current active or paused session for the authenticated user.
  Future<void> restoreActiveSession() async {
    if (_isAuthInvalid()) {
      _emit(const ActiveWorkoutState.authInvalidated());
      return;
    }
    if (_isActionInFlight) return;

    final priorState = state;
    _isActionInFlight = true;
    final version = ++_version;
    _emit(state.copyWith(status: ActiveWorkoutStatus.restoring));

    try {
      final record = await _repository.getActiveSession();
      if (_disposed || version != _version || _isAuthInvalid()) return;

      if (record == null || record.session.isTerminal) {
        _emit(const ActiveWorkoutState.noSession());
        return;
      }

      _applyAuthoritativeRecord(record);
    } on WorkoutSessionPersistenceException catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return;
      if (e.kind == WorkoutSessionPersistenceFailureKind.unauthenticated ||
          e.kind == WorkoutSessionPersistenceFailureKind.unauthorized) {
        _emit(const ActiveWorkoutState.authInvalidated());
      } else {
        _emit(priorState.copyWith(
          status: ActiveWorkoutStatus.reconciliationRequired,
          reconciliationReason:
              priorState.reconciliationReason ?? 'restore_failed',
          errorMessage: e.message ?? 'Failed to restore active session',
        ));
      }
    } catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return;
      _emit(priorState.copyWith(
        status: ActiveWorkoutStatus.reconciliationRequired,
        reconciliationReason:
            priorState.reconciliationReason ?? 'restore_failed',
        errorMessage: 'Unexpected error restoring workout session: $e',
      ));
    } finally {
      _isActionInFlight = false;
    }
  }

  /// Starts a new active workout session from an existing pure-Dart [WorkoutSession].
  ///
  /// Prevents starting when an active or paused session is already running.
  /// Preserves the client-provided session identity across retries.
  Future<bool> startSession(WorkoutSession session) async {
    if (_isAuthInvalid()) {
      _emit(const ActiveWorkoutState.authInvalidated());
      return false;
    }
    if (_isActionInFlight) return false;

    if (state.isRunning ||
        state.status == ActiveWorkoutStatus.reconciliationRequired) {
      _emit(state.copyWith(
        errorMessage: state.status == ActiveWorkoutStatus.reconciliationRequired
            ? 'Cannot start a session: state reconciliation is required.'
            : 'Cannot start a new session while a workout is already in progress.',
      ));
      return false;
    }

    return _executeMutation(
      actionName: 'startSession',
      targetSessionId: session.id,
      mutation: () => _repository.startSession(session),
      onSuccess: _applyAuthoritativeRecord,
    );
  }

  /// Starts a new workout session from a validated Routine and composition context.
  ///
  /// Evaluates execution readiness using [WorkoutReadinessValidator]. Rejects
  /// invalid or unapproved routines before dispatching to persistence.
  Future<bool> startSessionFromRoutine({
    required Program program,
    required Routine routine,
    required RoutineComposition composition,
    required Map<ExerciseRef, Exercise> resolvedExercises,
    required String localDate,
    DateTime? startedAtUtc,
  }) async {
    if (_isAuthInvalid()) {
      _emit(const ActiveWorkoutState.authInvalidated());
      return false;
    }
    if (_isActionInFlight) return false;

    if (state.isRunning ||
        state.status == ActiveWorkoutStatus.reconciliationRequired) {
      _emit(state.copyWith(
        errorMessage: state.status == ActiveWorkoutStatus.reconciliationRequired
            ? 'Cannot start a session: state reconciliation is required.'
            : 'Cannot start a new session while a workout is already in progress.',
      ));
      return false;
    }

    final userId = _currentUserId();
    if (userId == null) {
      _emit(const ActiveWorkoutState.authInvalidated());
      return false;
    }

    final evaluationTime = startedAtUtc ?? _nowUtc();
    final readiness = WorkoutReadinessValidator.evaluate(
      userId: userId,
      program: program,
      routine: routine,
      composition: composition,
      resolvedExercises: resolvedExercises,
      evaluationTimeUtc: evaluationTime,
    );

    if (readiness is! WorkoutExecutionReady) {
      final rejected = readiness as WorkoutExecutionRejected;
      _emit(state.copyWith(
        errorMessage: 'Routine not ready for execution: ${rejected.message}',
      ));
      return false;
    }

    final sessionId = WorkoutSessionId(_uuidGenerator());
    final session = WorkoutSession.start(
      id: sessionId,
      userId: userId,
      programId: program.id,
      routineId: routine.id,
      snapshot: readiness.snapshot,
      localDate: localDate,
      startedAtUtc: evaluationTime,
    );

    return startSession(session);
  }

  /// Logs or updates a performed set in the current active/paused session.
  ///
  /// Requires valid [reps] (>= 0) and/or [loadKg] (>= 0).
  /// Generates a stable client UUID if [setId] is not provided.
  Future<bool> logSet({
    required int sessionExerciseIndex,
    required int setIndex,
    int? reps,
    double? loadKg,
    int? durationSeconds,
    double? distanceMeters,
    bool isSkipped = false,
    String? notes,
    String? setId,
    DateTime? completedAtUtc,
  }) async {
    final currentRecord = state.record;
    if (currentRecord == null || !state.isRunning) {
      _emit(state.copyWith(
        errorMessage: 'Cannot log a set without an active workout session.',
      ));
      return false;
    }

    if (sessionExerciseIndex < 0) {
      _emit(state.copyWith(errorMessage: 'sessionExerciseIndex must be non-negative'));
      return false;
    }
    if (setIndex < 0) {
      _emit(state.copyWith(errorMessage: 'setIndex must be non-negative'));
      return false;
    }

    final snapshot = currentRecord.session.snapshot;
    if (sessionExerciseIndex >= snapshot.exercises.length) {
      _emit(state.copyWith(
        errorMessage: 'Invalid exercise occurrence index: $sessionExerciseIndex',
      ));
      return false;
    }

    final exerciseSnapshot = snapshot.exercises[sessionExerciseIndex];
    final performedSetId = setId ?? _uuidGenerator();

    final PerformedSet performedSet;
    try {
      performedSet = PerformedSet(
        id: performedSetId,
        exerciseRef: exerciseSnapshot.exerciseRef,
        sessionExerciseIndex: sessionExerciseIndex,
        setIndex: setIndex,
        reps: reps,
        loadKg: loadKg,
        durationSeconds: durationSeconds,
        distanceMeters: distanceMeters,
        completedAtUtc: completedAtUtc ?? _nowUtc(),
        isSkipped: isSkipped,
        notes: notes,
      );
    } on ArgumentError catch (e) {
      _emit(state.copyWith(errorMessage: e.message?.toString() ?? e.toString()));
      return false;
    }

    final expectedRevision = currentRecord.revision;
    final sessionId = currentRecord.session.id;

    return _executeMutation(
      actionName: 'logSet',
      targetSessionId: sessionId,
      mutation: () => _repository.logPerformedSet(
        sessionId: sessionId,
        expectedRevision: expectedRevision,
        set: performedSet,
      ),
      onSuccess: _applyAuthoritativeRecord,
    );
  }

  /// Removes a previously logged performed set by its canonical [setId].
  Future<bool> removeSet(String setId) async {
    final currentRecord = state.record;
    if (currentRecord == null || !state.isRunning) {
      _emit(state.copyWith(
        errorMessage: 'Cannot remove a set without an active workout session.',
      ));
      return false;
    }

    final expectedRevision = currentRecord.revision;
    final sessionId = currentRecord.session.id;

    return _executeMutation(
      actionName: 'removeSet',
      targetSessionId: sessionId,
      mutation: () => _repository.removePerformedSet(
        sessionId: sessionId,
        expectedRevision: expectedRevision,
        setId: setId,
      ),
      onSuccess: _applyAuthoritativeRecord,
    );
  }

  /// Pauses an active workout session.
  Future<bool> pauseSession({DateTime? pausedAtUtc}) async {
    final currentRecord = state.record;
    if (currentRecord == null || state.status != ActiveWorkoutStatus.active) {
      _emit(state.copyWith(
        errorMessage: 'Cannot pause session: workout is not actively running.',
      ));
      return false;
    }

    final expectedRevision = currentRecord.revision;
    final sessionId = currentRecord.session.id;
    final pauseInstant = pausedAtUtc ?? _nowUtc();

    return _executeMutation(
      actionName: 'pauseSession',
      targetSessionId: sessionId,
      mutation: () => _repository.pauseSession(
        sessionId: sessionId,
        expectedRevision: expectedRevision,
        pausedAtUtc: pauseInstant,
      ),
      onSuccess: _applyAuthoritativeRecord,
    );
  }

  /// Resumes a paused workout session.
  Future<bool> resumeSession({DateTime? resumedAtUtc}) async {
    final currentRecord = state.record;
    if (currentRecord == null || state.status != ActiveWorkoutStatus.paused) {
      _emit(state.copyWith(
        errorMessage: 'Cannot resume session: workout is not paused.',
      ));
      return false;
    }

    final expectedRevision = currentRecord.revision;
    final sessionId = currentRecord.session.id;
    final resumeInstant = resumedAtUtc ?? _nowUtc();

    return _executeMutation(
      actionName: 'resumeSession',
      targetSessionId: sessionId,
      mutation: () => _repository.resumeSession(
        sessionId: sessionId,
        expectedRevision: expectedRevision,
        resumedAtUtc: resumeInstant,
      ),
      onSuccess: _applyAuthoritativeRecord,
    );
  }

  /// Completes the active or paused workout session.
  Future<bool> completeSession({
    DateTime? completedAtUtc,
    String? notes,
  }) async {
    final currentRecord = state.record;
    if (currentRecord == null || !state.isRunning) {
      _emit(state.copyWith(
        errorMessage: 'Cannot complete session: no active session in progress.',
      ));
      return false;
    }

    final expectedRevision = currentRecord.revision;
    final sessionId = currentRecord.session.id;
    final completeInstant = completedAtUtc ?? _nowUtc();

    return _executeMutation(
      actionName: 'completeSession',
      targetSessionId: sessionId,
      mutation: () => _repository.completeSession(
        sessionId: sessionId,
        expectedRevision: expectedRevision,
        completedAtUtc: completeInstant,
        notes: notes,
      ),
      onSuccess: (finalRecord) {
        _applyAuthoritativeRecord(finalRecord, clearRestTimer: true);
      },
    );
  }

  /// Discards the active or paused workout session with an explicit [reason].
  Future<bool> discardSession({
    required String reason,
    DateTime? discardedAtUtc,
  }) async {
    final currentRecord = state.record;
    if (currentRecord == null || !state.isRunning) {
      _emit(state.copyWith(
        errorMessage: 'Cannot discard session: no active session in progress.',
      ));
      return false;
    }

    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      _emit(state.copyWith(errorMessage: 'Discard reason cannot be blank.'));
      return false;
    }

    final expectedRevision = currentRecord.revision;
    final sessionId = currentRecord.session.id;
    final discardInstant = discardedAtUtc ?? _nowUtc();

    return _executeMutation(
      actionName: 'discardSession',
      targetSessionId: sessionId,
      mutation: () => _repository.discardSession(
        sessionId: sessionId,
        expectedRevision: expectedRevision,
        discardedAtUtc: discardInstant,
        reason: trimmed,
      ),
      onSuccess: (finalRecord) {
        _applyAuthoritativeRecord(finalRecord, clearRestTimer: true);
      },
    );
  }

  /// Reconciles state against authoritative server truth after an uncertain
  /// outcome or OCC conflict.
  Future<bool> reconcileState() async {
    if (_isAuthInvalid()) {
      _emit(const ActiveWorkoutState.authInvalidated());
      return false;
    }
    if (_isActionInFlight) return false;

    _isActionInFlight = true;
    final targetId = state.sessionId;
    final version = ++_version;
    _emit(state.copyWith(
      isActionPending: true,
      pendingActionName: 'reconcile',
      clearErrorMessage: true,
    ));

    try {
      var record = targetId != null
          ? await _repository.getSession(targetId)
          : await _repository.getActiveSession();

      // A rejected duplicate start and an unknown start outcome retain the
      // attempted ID for safe recovery. That ID is not evidence that it ever
      // existed, though: another device may own the user's active session.
      // Resolve that owner-scoped canonical record before concluding absence.
      if (targetId != null && record == null) {
        if (_disposed || version != _version || _isAuthInvalid()) return false;
        record = await _repository.getActiveSession();
      }

      if (_disposed || version != _version || _isAuthInvalid()) return false;

      if (record == null) {
        _emit(const ActiveWorkoutState.noSession());
        return true;
      }

      _applyAuthoritativeRecord(record);
      return true;
    } on WorkoutSessionPersistenceException catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return false;
      if (e.kind == WorkoutSessionPersistenceFailureKind.unauthenticated ||
          e.kind == WorkoutSessionPersistenceFailureKind.unauthorized) {
        _emit(const ActiveWorkoutState.authInvalidated());
        return false;
      }
      _emit(state.copyWith(
        isActionPending: false,
        clearPendingAction: true,
        errorMessage: e.message ?? 'Reconciliation failed',
      ));
      return false;
    } catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return false;
      _emit(state.copyWith(
        isActionPending: false,
        clearPendingAction: true,
        errorMessage: 'Reconciliation error: $e',
      ));
      return false;
    } finally {
      _isActionInFlight = false;
      if (!_disposed && version == _version && state.isActionPending) {
        _emit(state.copyWith(
          isActionPending: false,
          clearPendingAction: true,
        ));
      }
    }
  }

  // --- Rest Timer Support ---

  /// Starts an in-memory rest timer for [durationSeconds].
  void startRestTimer({
    required int durationSeconds,
    int? sessionExerciseIndex,
    int? setIndex,
  }) {
    if (durationSeconds <= 0) {
      cancelRestTimer();
      return;
    }
    final target = _nowUtc().add(Duration(seconds: durationSeconds));
    _emit(state.copyWith(
      activeRestTimer: ActiveRestTimerState(
        targetInstantUtc: target,
        totalDurationSeconds: durationSeconds,
        sessionExerciseIndex: sessionExerciseIndex,
        setIndex: setIndex,
      ),
    ));
  }

  /// Cancels any active in-memory rest timer.
  void cancelRestTimer() {
    if (state.activeRestTimer != null) {
      _emit(state.copyWith(clearRestTimer: true));
    }
  }

  /// Adds [seconds] to the active rest timer.
  void addRestTimerSeconds(int seconds) {
    final current = state.activeRestTimer;
    if (current != null && seconds > 0) {
      _emit(state.copyWith(activeRestTimer: current.addSeconds(seconds)));
    }
  }

  /// Returns the prescribed rest duration in seconds for a specific set in the snapshot.
  int? getSuggestedRestSeconds({
    required int sessionExerciseIndex,
    required int setIndex,
  }) {
    final snapshot = state.snapshot;
    if (snapshot == null ||
        sessionExerciseIndex < 0 ||
        sessionExerciseIndex >= snapshot.exercises.length) {
      return null;
    }
    final exercise = snapshot.exercises[sessionExerciseIndex];
    if (setIndex < 0 || setIndex >= exercise.prescribedSets.length) {
      return null;
    }
    return exercise.prescribedSets[setIndex].restSeconds;
  }

  // --- Timing Ticker Support ---

  /// Starts a periodic UI ticker that updates [state.activeElapsedDuration].
  ///
  /// Safe to call multiple times. Ticker is cancelled on disposal or completion.
  void startDurationTicker({Duration interval = const Duration(seconds: 1)}) {
    _durationTicker?.cancel();
    _durationTicker = Timer.periodic(interval, (_) => updateElapsedDuration());
  }

  /// Stops the periodic UI duration ticker.
  void stopDurationTicker() {
    _durationTicker?.cancel();
    _durationTicker = null;
  }

  /// Re-evaluates active elapsed duration and expires rest timers if needed.
  void updateElapsedDuration() {
    if (_disposed || !state.isRunning) return;

    final session = state.session;
    if (session == null) return;

    final now = _nowUtc();
    final elapsed = _calculateElapsedDuration(
      session,
      now,
      enforceMonotonic: true,
    );

    ActiveRestTimerState? restTimer = state.activeRestTimer;
    if (restTimer != null && restTimer.isExpired(now)) {
      restTimer = null;
    }

    if (elapsed != state.activeElapsedDuration ||
        restTimer != state.activeRestTimer) {
      _emit(state.copyWith(
        activeElapsedDuration: elapsed,
        activeRestTimer: restTimer,
        clearRestTimer: restTimer == null,
      ));
    }
  }

  // --- Authentication Safety ---

  /// Invoked when the auth environment changes (e.g. sign-out, account switch).
  ///
  /// Clears private in-memory session data and invalidates controller capabilities.
  void onAuthChanged() {
    if (_isAuthInvalid()) {
      _version++;
      _isActionInFlight = false;
      stopDurationTicker();
      _emit(const ActiveWorkoutState.authInvalidated());
    }
  }

  // --- Internal Mutation Helper ---

  Future<bool> _executeMutation({
    required String actionName,
    required WorkoutSessionId targetSessionId,
    required Future<WorkoutSessionRecord> Function() mutation,
    required void Function(WorkoutSessionRecord record) onSuccess,
  }) async {
    if (_isAuthInvalid()) {
      _emit(const ActiveWorkoutState.authInvalidated());
      return false;
    }
    if (_isActionInFlight) return false;

    _isActionInFlight = true;
    final version = ++_version;
    final isNewSession = targetSessionId != state.record?.session.id;
    _emit(state.copyWith(
      isActionPending: true,
      pendingActionName: actionName,
      clearErrorMessage: true,
      clearRecord: isNewSession,
      lastKnownSessionId: targetSessionId,
      activeElapsedDuration:
          isNewSession ? Duration.zero : state.activeElapsedDuration,
      clearRestTimer: isNewSession,
    ));

    try {
      final record = await mutation();
      if (_disposed || version != _version || _isAuthInvalid()) return false;

      _emit(state.copyWith(
        isActionPending: false,
        clearPendingAction: true,
      ));
      onSuccess(record);
      return true;
    } on WorkoutSessionCommittedReadbackException catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return false;
      _emit(state.copyWith(
        status: ActiveWorkoutStatus.reconciliationRequired,
        isActionPending: false,
        clearPendingAction: true,
        clearRecord: isNewSession,
        reconciliationReason: 'committed_readback_failed',
        lastKnownSessionId: e.sessionId,
        errorMessage: e.message ??
            'Mutation acknowledged by server but readback failed. Please reconcile.',
      ));
      return false;
    } on WorkoutSessionMutationOutcomeUnknown catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return false;
      _emit(state.copyWith(
        status: ActiveWorkoutStatus.reconciliationRequired,
        isActionPending: false,
        clearPendingAction: true,
        clearRecord: isNewSession,
        reconciliationReason: e.reason.name,
        lastKnownSessionId: e.sessionId,
        errorMessage:
            'Mutation outcome uncertain (${e.reason.name}). Please reconcile before retrying.',
      ));
      return false;
    } on WorkoutSessionPersistenceException catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return false;
      if (e.kind == WorkoutSessionPersistenceFailureKind.unauthenticated ||
          e.kind == WorkoutSessionPersistenceFailureKind.unauthorized) {
        _emit(const ActiveWorkoutState.authInvalidated());
        return false;
      }
      if (isNewSession &&
          actionName == 'startSession' &&
          e.kind == WorkoutSessionPersistenceFailureKind.duplicateActiveSession) {
        // This is a known rejected start, not an unknown mutation outcome.
        // The user still has an authoritative active/paused session that must
        // be discovered before another start can be attempted.
        _emit(state.copyWith(
          status: ActiveWorkoutStatus.reconciliationRequired,
          isActionPending: false,
          clearPendingAction: true,
          clearRecord: true,
          lastKnownSessionId: targetSessionId,
          reconciliationReason: 'duplicate_active_session',
          errorMessage:
              'Another active workout session exists. Please reconcile before starting a new session.',
        ));
        return false;
      }
      if (e.kind == WorkoutSessionPersistenceFailureKind.staleRevisionConflict) {
        _emit(state.copyWith(
          status: ActiveWorkoutStatus.reconciliationRequired,
          isActionPending: false,
          clearPendingAction: true,
          clearRecord: isNewSession,
          lastKnownSessionId: targetSessionId,
          reconciliationReason: 'stale_revision_conflict',
          errorMessage: 'Revision conflict: session was updated on another device. Please reconcile.',
        ));
        return false;
      }
      _emit(state.copyWith(
        isActionPending: false,
        clearPendingAction: true,
        clearRecord: isNewSession,
        lastKnownSessionId: targetSessionId,
        errorMessage: e.message ?? 'Persistence failure (${e.kind.name})',
      ));
      return false;
    } catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return false;
      _emit(state.copyWith(
        isActionPending: false,
        clearPendingAction: true,
        clearRecord: isNewSession,
        lastKnownSessionId: targetSessionId,
        errorMessage: 'Unexpected error: $e',
      ));
      return false;
    } finally {
      _isActionInFlight = false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _isActionInFlight = false;
    stopDurationTicker();
    super.dispose();
  }
}

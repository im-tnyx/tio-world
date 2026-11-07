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

  bool _isAuthInvalid() {
    final liveId = _currentUserId();
    return liveId == null || liveId != _initialOwnerId;
  }

  void _emit(ActiveWorkoutState next) {
    if (_disposed) return;
    _state = next;
    notifyListeners();
  }

  /// Restores any current active or paused session for the authenticated user.
  Future<void> restoreActiveSession() async {
    if (_isAuthInvalid()) {
      _emit(const ActiveWorkoutState.authInvalidated());
      return;
    }
    final version = ++_version;
    _emit(state.copyWith(status: ActiveWorkoutStatus.restoring));

    try {
      final record = await _repository.getActiveSession();
      if (_disposed || version != _version || _isAuthInvalid()) return;

      if (record == null) {
        _emit(const ActiveWorkoutState.noSession());
        return;
      }

      final status = record.session.status;
      if (status == WorkoutSessionStatus.active) {
        final elapsed = record.session.time.elapsedActiveDuration(_nowUtc());
        _emit(ActiveWorkoutState(
          status: ActiveWorkoutStatus.active,
          record: record,
          activeElapsedDuration: elapsed,
          lastKnownSessionId: record.session.id,
        ));
      } else if (status == WorkoutSessionStatus.paused) {
        final elapsed = record.session.time.elapsedActiveDuration(_nowUtc());
        _emit(ActiveWorkoutState(
          status: ActiveWorkoutStatus.paused,
          record: record,
          activeElapsedDuration: elapsed,
          lastKnownSessionId: record.session.id,
        ));
      } else {
        // Defensively treat completed/discarded records as no active session.
        _emit(const ActiveWorkoutState.noSession());
      }
    } on WorkoutSessionPersistenceException catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return;
      if (e.kind == WorkoutSessionPersistenceFailureKind.unauthenticated ||
          e.kind == WorkoutSessionPersistenceFailureKind.unauthorized) {
        _emit(const ActiveWorkoutState.authInvalidated());
      } else {
        _emit(state.copyWith(
          status: ActiveWorkoutStatus.noSession,
          errorMessage: e.message ?? 'Failed to restore active session',
        ));
      }
    } catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return;
      _emit(state.copyWith(
        status: ActiveWorkoutStatus.noSession,
        errorMessage: 'Unexpected error restoring workout session: $e',
      ));
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

    if (state.isRunning) {
      _emit(state.copyWith(
        errorMessage:
            'Cannot start a new session while a workout is already in progress.',
      ));
      return false;
    }

    return _executeMutation(
      actionName: 'startSession',
      targetSessionId: session.id,
      mutation: () => _repository.startSession(session),
      onSuccess: (record) {
        final elapsed = record.session.time.elapsedActiveDuration(_nowUtc());
        _emit(ActiveWorkoutState(
          status: ActiveWorkoutStatus.active,
          record: record,
          activeElapsedDuration: elapsed,
          lastKnownSessionId: record.session.id,
        ));
      },
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

    if (state.isRunning) {
      _emit(state.copyWith(
        errorMessage:
            'Cannot start a new session while a workout is already in progress.',
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
      onSuccess: (updatedRecord) {
        final elapsed =
            updatedRecord.session.time.elapsedActiveDuration(_nowUtc());
        _emit(state.copyWith(
          record: updatedRecord,
          activeElapsedDuration: elapsed,
          clearErrorMessage: true,
        ));
      },
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
      onSuccess: (updatedRecord) {
        final elapsed =
            updatedRecord.session.time.elapsedActiveDuration(_nowUtc());
        _emit(state.copyWith(
          record: updatedRecord,
          activeElapsedDuration: elapsed,
          clearErrorMessage: true,
        ));
      },
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
      onSuccess: (updatedRecord) {
        final elapsed =
            updatedRecord.session.time.elapsedActiveDuration(_nowUtc());
        _emit(state.copyWith(
          status: ActiveWorkoutStatus.paused,
          record: updatedRecord,
          activeElapsedDuration: elapsed,
          clearErrorMessage: true,
        ));
      },
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
      onSuccess: (updatedRecord) {
        final elapsed =
            updatedRecord.session.time.elapsedActiveDuration(_nowUtc());
        _emit(state.copyWith(
          status: ActiveWorkoutStatus.active,
          record: updatedRecord,
          activeElapsedDuration: elapsed,
          clearErrorMessage: true,
        ));
      },
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
        stopDurationTicker();
        final elapsed =
            finalRecord.session.time.elapsedActiveDuration(_nowUtc());
        _emit(ActiveWorkoutState(
          status: ActiveWorkoutStatus.completed,
          record: finalRecord,
          activeElapsedDuration: elapsed,
          lastKnownSessionId: finalRecord.session.id,
        ));
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
        stopDurationTicker();
        final elapsed =
            finalRecord.session.time.elapsedActiveDuration(_nowUtc());
        _emit(ActiveWorkoutState(
          status: ActiveWorkoutStatus.discarded,
          record: finalRecord,
          activeElapsedDuration: elapsed,
          lastKnownSessionId: finalRecord.session.id,
        ));
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

    final targetId = state.sessionId;
    final version = ++_version;
    _emit(state.copyWith(
      isActionPending: true,
      pendingActionName: 'reconcile',
      clearErrorMessage: true,
    ));

    try {
      final record = targetId != null
          ? await _repository.getSession(targetId)
          : await _repository.getActiveSession();

      if (_disposed || version != _version || _isAuthInvalid()) return false;

      if (record == null) {
        _emit(const ActiveWorkoutState.noSession());
        return true;
      }

      final status = record.session.status;
      final elapsed = record.session.time.elapsedActiveDuration(_nowUtc());

      switch (status) {
        case WorkoutSessionStatus.active:
          _emit(ActiveWorkoutState(
            status: ActiveWorkoutStatus.active,
            record: record,
            activeElapsedDuration: elapsed,
            lastKnownSessionId: record.session.id,
          ));
          return true;
        case WorkoutSessionStatus.paused:
          _emit(ActiveWorkoutState(
            status: ActiveWorkoutStatus.paused,
            record: record,
            activeElapsedDuration: elapsed,
            lastKnownSessionId: record.session.id,
          ));
          return true;
        case WorkoutSessionStatus.completed:
          stopDurationTicker();
          _emit(ActiveWorkoutState(
            status: ActiveWorkoutStatus.completed,
            record: record,
            activeElapsedDuration: elapsed,
            lastKnownSessionId: record.session.id,
          ));
          return true;
        case WorkoutSessionStatus.discarded:
          stopDurationTicker();
          _emit(ActiveWorkoutState(
            status: ActiveWorkoutStatus.discarded,
            record: record,
            activeElapsedDuration: elapsed,
            lastKnownSessionId: record.session.id,
          ));
          return true;
      }
    } on WorkoutSessionPersistenceException catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return false;
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
    final elapsed = session.time.elapsedActiveDuration(now);

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
    _emit(state.copyWith(
      isActionPending: true,
      pendingActionName: actionName,
      clearErrorMessage: true,
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
      if (e.kind == WorkoutSessionPersistenceFailureKind.staleRevisionConflict) {
        _emit(state.copyWith(
          status: ActiveWorkoutStatus.reconciliationRequired,
          isActionPending: false,
          clearPendingAction: true,
          reconciliationReason: 'stale_revision_conflict',
          errorMessage: 'Revision conflict: session was updated on another device. Please reconcile.',
        ));
        return false;
      }
      _emit(state.copyWith(
        isActionPending: false,
        clearPendingAction: true,
        errorMessage: e.message ?? 'Persistence failure (${e.kind.name})',
      ));
      return false;
    } catch (e) {
      if (_disposed || version != _version || _isAuthInvalid()) return false;
      _emit(state.copyWith(
        isActionPending: false,
        clearPendingAction: true,
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
    stopDurationTicker();
    super.dispose();
  }
}

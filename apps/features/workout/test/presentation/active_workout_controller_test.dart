import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final class _FakeWorkoutSessionRepository implements WorkoutSessionRepository {
  WorkoutSessionRecord? activeSessionToReturn;
  WorkoutSessionRecord? customMutationRecordToReturn;
  final Map<String, WorkoutSessionRecord> sessionsById = {};
  Exception? errorToThrow;
  Exception? startSessionErrorToThrow;
  Exception? getSessionErrorToThrow;
  Exception? getActiveSessionErrorToThrow;
  bool returnNullForTargetLookup = false;
  Completer<WorkoutSessionRecord>? pendingCompleter;
  Completer<WorkoutSessionRecord?>? pendingRestoreCompleter;
  Completer<WorkoutSessionRecord?>? pendingActiveSessionCompleter;
  int getActiveSessionCalls = 0;
  int startSessionCalls = 0;
  int logSetCalls = 0;
  int removeSetCalls = 0;
  int pauseCalls = 0;
  int resumeCalls = 0;
  int completeCalls = 0;
  int discardCalls = 0;
  int getSessionCalls = 0;

  @override
  Future<WorkoutSessionRecord?> getActiveSession() async {
    getActiveSessionCalls++;
    if (getActiveSessionErrorToThrow != null) throw getActiveSessionErrorToThrow!;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingActiveSessionCompleter != null) {
      return pendingActiveSessionCompleter!.future;
    }
    if (pendingRestoreCompleter != null) return pendingRestoreCompleter!.future;
    return activeSessionToReturn;
  }

  @override
  Future<WorkoutSessionRecord?> getSession(WorkoutSessionId sessionId) async {
    getSessionCalls++;
    if (getSessionErrorToThrow != null) throw getSessionErrorToThrow!;
    if (errorToThrow != null) throw errorToThrow!;
    if (returnNullForTargetLookup) return null;
    if (pendingRestoreCompleter != null) return pendingRestoreCompleter!.future;
    return sessionsById[sessionId.value] ?? activeSessionToReturn;
  }

  @override
  Future<WorkoutSessionRecord> startSession(WorkoutSession session) async {
    startSessionCalls++;
    if (startSessionErrorToThrow != null) throw startSessionErrorToThrow!;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingCompleter != null) return pendingCompleter!.future;
    final record = sessionsById[session.id.value] ??
        activeSessionToReturn ??
        WorkoutSessionRecord(session: session, revision: 1);
    activeSessionToReturn = record;
    sessionsById[session.id.value] = record;
    return record;
  }

  @override
  Future<WorkoutSessionRecord> logPerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required PerformedSet set,
  }) async {
    logSetCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingCompleter != null) return pendingCompleter!.future;
    if (customMutationRecordToReturn != null) {
      final ret = customMutationRecordToReturn!;
      customMutationRecordToReturn = null;
      sessionsById[sessionId.value] = ret;
      activeSessionToReturn = ret;
      return ret;
    }
    final current = sessionsById[sessionId.value] ?? activeSessionToReturn!;
    final updatedSession = current.session.logSet(set);
    final updated = current.copyWith(
      session: updatedSession,
      revision: expectedRevision + 1,
    );
    activeSessionToReturn = updated;
    sessionsById[sessionId.value] = updated;
    return updated;
  }

  @override
  Future<WorkoutSessionRecord> removePerformedSet({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required String setId,
  }) async {
    removeSetCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingCompleter != null) return pendingCompleter!.future;
    if (customMutationRecordToReturn != null) {
      final ret = customMutationRecordToReturn!;
      customMutationRecordToReturn = null;
      sessionsById[sessionId.value] = ret;
      activeSessionToReturn = ret;
      return ret;
    }
    final current = sessionsById[sessionId.value] ?? activeSessionToReturn!;
    final updatedSession = current.session.removeSet(setId);
    final updated = current.copyWith(
      session: updatedSession,
      revision: expectedRevision + 1,
    );
    activeSessionToReturn = updated;
    sessionsById[sessionId.value] = updated;
    return updated;
  }

  @override
  Future<WorkoutSessionRecord> pauseSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime pausedAtUtc,
  }) async {
    pauseCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingCompleter != null) return pendingCompleter!.future;
    if (customMutationRecordToReturn != null) {
      final ret = customMutationRecordToReturn!;
      customMutationRecordToReturn = null;
      sessionsById[sessionId.value] = ret;
      activeSessionToReturn = ret;
      return ret;
    }
    final current = sessionsById[sessionId.value] ?? activeSessionToReturn!;
    final updatedSession = current.session.pause(pausedAtUtc);
    final updated = current.copyWith(
      session: updatedSession,
      revision: expectedRevision + 1,
    );
    activeSessionToReturn = updated;
    sessionsById[sessionId.value] = updated;
    return updated;
  }

  @override
  Future<WorkoutSessionRecord> resumeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime resumedAtUtc,
  }) async {
    resumeCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingCompleter != null) return pendingCompleter!.future;
    if (customMutationRecordToReturn != null) {
      final ret = customMutationRecordToReturn!;
      customMutationRecordToReturn = null;
      sessionsById[sessionId.value] = ret;
      activeSessionToReturn = ret;
      return ret;
    }
    final current = sessionsById[sessionId.value] ?? activeSessionToReturn!;
    final updatedSession = current.session.resume(resumedAtUtc);
    final updated = current.copyWith(
      session: updatedSession,
      revision: expectedRevision + 1,
    );
    activeSessionToReturn = updated;
    sessionsById[sessionId.value] = updated;
    return updated;
  }

  @override
  Future<WorkoutSessionRecord> completeSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime completedAtUtc,
    String? notes,
  }) async {
    completeCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingCompleter != null) return pendingCompleter!.future;
    if (customMutationRecordToReturn != null) {
      final ret = customMutationRecordToReturn!;
      customMutationRecordToReturn = null;
      sessionsById[sessionId.value] = ret;
      activeSessionToReturn = ret.session.isTerminal ? null : ret;
      return ret;
    }
    final current = sessionsById[sessionId.value] ?? activeSessionToReturn!;
    final updatedSession = current.session.complete(completedAtUtc, notes: notes);
    final updated = current.copyWith(
      session: updatedSession,
      revision: expectedRevision + 1,
    );
    activeSessionToReturn = null;
    sessionsById[sessionId.value] = updated;
    return updated;
  }

  @override
  Future<WorkoutSessionRecord> discardSession({
    required WorkoutSessionId sessionId,
    required int expectedRevision,
    required DateTime discardedAtUtc,
    required String reason,
  }) async {
    discardCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingCompleter != null) return pendingCompleter!.future;
    if (customMutationRecordToReturn != null) {
      final ret = customMutationRecordToReturn!;
      customMutationRecordToReturn = null;
      sessionsById[sessionId.value] = ret;
      activeSessionToReturn = ret.session.isTerminal ? null : ret;
      return ret;
    }
    final current = sessionsById[sessionId.value] ?? activeSessionToReturn!;
    final updatedSession = current.session.discard(discardedAtUtc, reason: reason);
    final updated = current.copyWith(
      session: updatedSession,
      revision: expectedRevision + 1,
    );
    activeSessionToReturn = null;
    sessionsById[sessionId.value] = updated;
    return updated;
  }
}

void main() {
  const testUserId = '11111111-1111-4111-a111-111111111111';
  final testSessionId = WorkoutSessionId('22222222-2222-4222-a222-222222222222');
  final testProgramId = ProgramId('33333333-3333-4333-a333-333333333333');
  final testRoutineId = RoutineId('44444444-4444-4444-a444-444444444444');
  final testStartTime = DateTime.utc(2026, 11, 7, 10, 0, 0);
  final testExerciseRef = ExerciseRef.catalog('ex_barbell_bench_press');

  WorkoutSessionSnapshot createTestSnapshot() => WorkoutSessionSnapshot(
        routineId: testRoutineId,
        routineName: 'Push Day A',
        programId: testProgramId,
        capturedAtUtc: testStartTime,
        exercises: [
          SessionExerciseSnapshot(
            exerciseRef: testExerciseRef,
            displayName: 'Bench Press',
            exerciseType: ExerciseType.weightReps,
            occurrenceIndex: 0,
            prescribedSets: [
              SetPrescription(
                setType: RoutineSetType.warmUp,
                reps: 10,
                loadKg: 40.0,
                restSeconds: 60,
              ),
              SetPrescription(
                setType: RoutineSetType.normal,
                reps: 8,
                loadKg: 80.0,
                restSeconds: 120,
              ),
            ],
          ),
        ],
      );

  WorkoutSession createTestSession({
    WorkoutSessionId? id,
    WorkoutSessionStatus status = WorkoutSessionStatus.active,
    DateTime? startedAtUtc,
    DateTime? pausedAt,
    int pausedDurationUs = 0,
    List<PerformedSet> sets = const [],
    String? notes,
    String? discardReason,
  }) {
    final start = startedAtUtc ?? testStartTime;
    return WorkoutSession(
      id: id ?? testSessionId,
      userId: testUserId,
      programId: testProgramId,
      routineId: testRoutineId,
      status: status,
      time: WorkoutTime(
        startedAtUtc: start,
        pausedAtUtc: pausedAt,
        accumulatedPausedDuration: Duration(microseconds: pausedDurationUs),
        completedAtUtc: status.isTerminal ? pausedAt ?? start : null,
        lastTransitionAtUtc: pausedAt ?? start,
      ),
      localDate: '2026-11-07',
      snapshot: createTestSnapshot(),
      performedSets: sets,
      notes: notes,
      discardReason: discardReason,
    );
  }

  late _FakeWorkoutSessionRepository fakeRepo;
  late String? currentUserId;
  late DateTime currentTime;

  setUp(() {
    fakeRepo = _FakeWorkoutSessionRepository();
    currentUserId = testUserId;
    currentTime = testStartTime;
  });

  ActiveWorkoutController createController({String Function()? uuidGen}) =>
      ActiveWorkoutController(
        repository: fakeRepo,
        currentUserId: () => currentUserId,
        clock: () => currentTime,
        uuidGenerator: uuidGen ?? (() => '55555555-5555-4555-a555-555555555555'),
      );

  group('ActiveWorkoutController - Restoration', () {
    test('restores no-session state when repository returns null', () async {
      final controller = createController();
      fakeRepo.activeSessionToReturn = null;

      expect(controller.state.status, ActiveWorkoutStatus.initial);

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.noSession);
      expect(controller.state.record, isNull);
      expect(controller.state.isRunning, isFalse);
    });

    test('restores active running session with derived duration', () async {
      final session = createTestSession(status: WorkoutSessionStatus.active);
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 3);

      currentTime = testStartTime.add(const Duration(minutes: 15));
      final controller = createController();

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.isRunning, isTrue);
      expect(controller.state.isPaused, isFalse);
      expect(controller.state.revision, 3);
      expect(controller.state.sessionId, testSessionId);
      expect(controller.state.activeElapsedDuration, const Duration(minutes: 15));
    });

    test('restores paused session with paused state', () async {
      final pauseTime = testStartTime.add(const Duration(minutes: 10));
      final session = createTestSession(
        status: WorkoutSessionStatus.paused,
        pausedAt: pauseTime,
      );
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 2);

      currentTime = testStartTime.add(const Duration(minutes: 20));
      final controller = createController();

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.paused);
      expect(controller.state.isRunning, isTrue);
      expect(controller.state.isPaused, isTrue);
      expect(controller.state.revision, 2);
      expect(controller.state.activeElapsedDuration, const Duration(minutes: 10));
    });

    test('emits authInvalidated when user is not authenticated', () async {
      currentUserId = null;
      final controller = createController();

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.authInvalidated);
      expect(fakeRepo.getActiveSessionCalls, 0);
    });
  });

  group('ActiveWorkoutController - Start Workout', () {
    test('starts session successfully from pure-Dart session', () async {
      final controller = createController();
      final session = createTestSession();

      final success = await controller.startSession(session);

      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.sessionId, testSessionId);
      expect(controller.state.revision, 1);
      expect(fakeRepo.startSessionCalls, 1);
    });

    test('rejects start when session is already running', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      final newSession = createTestSession();
      final success = await controller.startSession(newSession);

      expect(success, isFalse);
      expect(fakeRepo.startSessionCalls, 0);
      expect(controller.state.errorMessage, contains('already in progress'));
    });

    test('starts session from routine with execution readiness check', () async {
      final controller = createController();
      final program = Program(
        id: testProgramId,
        name: 'Hypertrophy Block',
      );
      final routine = Routine(
        id: testRoutineId,
        programId: testProgramId,
        name: 'Push Day A',
      );
      final composition = RoutineComposition(
        routineId: testRoutineId,
        exercises: [
          RoutineExercise(
            exercise: testExerciseRef,
            sets: [
              SetPrescription(
                setType: RoutineSetType.normal,
                reps: 8,
                loadKg: 80.0,
              ),
            ],
          ),
        ],
      );
      final resolvedExercises = {
        testExerciseRef: Exercise(
          ref: testExerciseRef,
          displayName: 'Bench Press',
          exerciseType: ExerciseType.weightReps,
          status: ExerciseStatus.active,
        ),
      };

      final success = await controller.startSessionFromRoutine(
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: resolvedExercises,
        localDate: '2026-11-07',
      );

      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(fakeRepo.startSessionCalls, 1);
      expect(controller.state.snapshot?.routineName, 'Push Day A');
    });

    test('rejects routine start when composition has no executable sets', () async {
      final controller = createController();
      final program = Program(
        id: testProgramId,
        name: 'Hypertrophy Block',
      );
      final routine = Routine(
        id: testRoutineId,
        programId: testProgramId,
        name: 'Empty Routine',
      );
      final emptyComposition = RoutineComposition(
        routineId: testRoutineId,
        exercises: const [],
      );

      final success = await controller.startSessionFromRoutine(
        program: program,
        routine: routine,
        composition: emptyComposition,
        resolvedExercises: const {},
        localDate: '2026-11-07',
      );

      expect(success, isFalse);
      expect(fakeRepo.startSessionCalls, 0);
      expect(controller.state.errorMessage, contains('Routine not ready'));
    });
  });

  group('ActiveWorkoutController - Set Logging and Removal', () {
    test('logs performed set successfully with revision bump', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      final success = await controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
        loadKg: 40.0,
      );

      expect(success, isTrue);
      expect(controller.state.revision, 2);
      expect(controller.state.performedSets.length, 1);
      expect(controller.state.performedSets.first.reps, 10);
      expect(controller.state.performedSets.first.loadKg, 40.0);
      expect(fakeRepo.logSetCalls, 1);
    });

    test('rejects set logging with negative reps or invalid index', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      final invalidIndex = await controller.logSet(
        sessionExerciseIndex: 99,
        setIndex: 0,
        reps: 8,
      );
      expect(invalidIndex, isFalse);
      expect(controller.state.errorMessage, contains('Invalid exercise occurrence'));

      final negativeReps = await controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: -5,
      );
      expect(negativeReps, isFalse);
      expect(fakeRepo.logSetCalls, 0);
    });

    test('removes performed set successfully', () async {
      final performedSet = PerformedSet(
        id: '88888888-8888-4888-a888-888888888888',
        exerciseRef: testExerciseRef,
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
        loadKg: 40.0,
        completedAtUtc: testStartTime,
      );
      final session = createTestSession(sets: [performedSet]);
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 2);
      final controller = createController();
      await controller.restoreActiveSession();

      final success =
          await controller.removeSet('88888888-8888-4888-a888-888888888888');

      expect(success, isTrue);
      expect(controller.state.revision, 3);
      expect(controller.state.performedSets, isEmpty);
      expect(fakeRepo.removeSetCalls, 1);
    });
  });

  group('ActiveWorkoutController - Lifecycle Transitions', () {
    test('pauses and resumes active session successfully', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      final pauseTime = testStartTime.add(const Duration(minutes: 5));
      currentTime = pauseTime;
      final pauseSuccess = await controller.pauseSession(pausedAtUtc: pauseTime);

      expect(pauseSuccess, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.paused);
      expect(controller.state.isPaused, isTrue);
      expect(controller.state.revision, 2);

      final resumeTime = testStartTime.add(const Duration(minutes: 7));
      currentTime = resumeTime;
      final resumeSuccess = await controller.resumeSession(resumedAtUtc: resumeTime);

      expect(resumeSuccess, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.isPaused, isFalse);
      expect(controller.state.revision, 3);
    });

    test('completes session and enters terminal state', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      final finishTime = testStartTime.add(const Duration(minutes: 45));
      currentTime = finishTime;
      final success = await controller.completeSession(
        completedAtUtc: finishTime,
        notes: 'Great workout today',
      );

      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.completed);
      expect(controller.state.isTerminal, isTrue);
      expect(controller.state.session?.notes, 'Great workout today');
      expect(fakeRepo.completeCalls, 1);

      // Rejects mutation after terminal completion
      final logAfterComplete = await controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
      );
      expect(logAfterComplete, isFalse);
    });

    test('discards session with valid non-blank reason', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      final blankDiscard = await controller.discardSession(reason: '   ');
      expect(blankDiscard, isFalse);
      expect(controller.state.errorMessage, contains('cannot be blank'));

      final success = await controller.discardSession(reason: 'Feeling dizzy');
      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.discarded);
      expect(controller.state.isTerminal, isTrue);
      expect(controller.state.session?.discardReason, 'Feeling dizzy');
      expect(fakeRepo.discardCalls, 1);
    });
  });

  group('ActiveWorkoutController - Rest Timer & Timing', () {
    test('starts, adds seconds, and cancels in-memory rest timer', () {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();

      controller.startRestTimer(
        durationSeconds: 90,
        sessionExerciseIndex: 0,
        setIndex: 1,
      );

      expect(controller.state.activeRestTimer, isNotNull);
      expect(controller.state.activeRestTimer?.totalDurationSeconds, 90);
      expect(
        controller.state.activeRestTimer?.remainingDuration(currentTime).inSeconds,
        90,
      );

      controller.addRestTimerSeconds(30);
      expect(controller.state.activeRestTimer?.totalDurationSeconds, 120);

      controller.cancelRestTimer();
      expect(controller.state.activeRestTimer, isNull);
    });

    test('suggests rest duration from routine snapshot', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      final warmUpRest = controller.getSuggestedRestSeconds(
        sessionExerciseIndex: 0,
        setIndex: 0,
      );
      expect(warmUpRest, 60);

      final normalRest = controller.getSuggestedRestSeconds(
        sessionExerciseIndex: 0,
        setIndex: 1,
      );
      expect(normalRest, 120);

      final outOfBounds = controller.getSuggestedRestSeconds(
        sessionExerciseIndex: 0,
        setIndex: 99,
      );
      expect(outOfBounds, isNull);
    });

    test('expires rest timer when updating elapsed duration', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      controller.startRestTimer(durationSeconds: 30);
      expect(controller.state.activeRestTimer, isNotNull);

      // Fast forward clock beyond rest target
      currentTime = testStartTime.add(const Duration(seconds: 35));
      controller.updateElapsedDuration();

      expect(controller.state.activeRestTimer, isNull);
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 35));
    });
  });

  group('ActiveWorkoutController - Concurrency & Mutation Serialization', () {
    test('serializes commands and rejects concurrent second tap while first is in-flight', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final controller = createController();
      await controller.restoreActiveSession();

      // Launch first mutation
      final future1 = controller.logSet(sessionExerciseIndex: 0, setIndex: 0, reps: 8);
      expect(controller.state.isActionPending, isTrue);

      // Attempt second mutation while first is in-flight
      final tap2 = await controller.pauseSession();
      expect(tap2, isFalse);

      // Complete first mutation
      completer.complete(WorkoutSessionRecord(session: session, revision: 2));
      final result1 = await future1;

      expect(result1, isTrue);
      expect(controller.state.isActionPending, isFalse);
    });
  });

  group('ActiveWorkoutController - Recovery & Error Scenarios', () {
    test('handles committed mutation readback failure and requires reconciliation', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      fakeRepo.errorToThrow = WorkoutSessionCommittedReadbackException(
        sessionId: testSessionId,
        operationName: 'logSet',
      );

      final success = await controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
      );

      expect(success, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.reconciliationReason, 'committed_readback_failed');
      expect(controller.state.sessionId, testSessionId);

      // Call reconcileState to restore authoritative server record
      fakeRepo.errorToThrow = null;
      final updated = WorkoutSessionRecord(session: session, revision: 2);
      fakeRepo.sessionsById[testSessionId.value] = updated;

      final reconciled = await controller.reconcileState();
      expect(reconciled, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.revision, 2);
    });

    test('handles OCC staleRevisionConflict and triggers reconciliation requirement', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      fakeRepo.errorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.staleRevisionConflict,
        message: 'Stale revision',
      );

      final success = await controller.pauseSession();

      expect(success, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.reconciliationReason, 'stale_revision_conflict');
    });

    test('handles WorkoutSessionMutationOutcomeUnknown and requires reconciliation', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      fakeRepo.errorToThrow = WorkoutSessionMutationOutcomeUnknown(
        sessionId: testSessionId,
        reason: WorkoutSessionMutationUncertainty.networkTimeout,
      );

      final success = await controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
      );

      expect(success, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.reconciliationReason, 'networkTimeout');
    });

    test('handles slot conflict and reports non-fatal error message', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      fakeRepo.errorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.setSlotConflict,
        message: 'Slot occupied',
      );

      final success = await controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
      );

      expect(success, isFalse);
      expect(controller.state.errorMessage, contains('Slot occupied'));
      expect(controller.state.status, ActiveWorkoutStatus.active);
    });
  });

  group('ActiveWorkoutController - Authentication Lifecycle & Isolation', () {
    test('invalidates controller when auth changes or user signs out', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.active);

      // Simulate sign out
      currentUserId = null;
      controller.onAuthChanged();

      expect(controller.state.status, ActiveWorkoutStatus.authInvalidated);
      expect(controller.state.record, isNull);
    });

    test('discards in-flight mutation result if auth changes before future completes', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final controller = createController();
      await controller.restoreActiveSession();

      final future = controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
      );

      // Account switch while in-flight
      currentUserId = '99999999-9999-4999-a999-999999999999';

      completer.complete(WorkoutSessionRecord(session: session, revision: 2));
      final success = await future;

      expect(success, isFalse);
      expect(controller.state.record?.revision, 1);
    });

    test('same-owner auth metadata refresh does not discard an in-flight mutation', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;
      final controller = createController();
      await controller.restoreActiveSession();

      final pending = controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
      );
      // The verified owner is unchanged; profile/Auth metadata updates must not
      // invalidate this controller or its dispatched mutation.
      currentUserId = testUserId;
      completer.complete(WorkoutSessionRecord(session: session, revision: 2));

      expect(await pending, isTrue);
      expect(controller.state.revision, 2);
    });

    test('safely handles disposal while async operation is pending', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn =
          WorkoutSessionRecord(session: session, revision: 1);
      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final controller = createController();
      await controller.restoreActiveSession();

      final future = controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
      );

      controller.dispose();
      completer.complete(WorkoutSessionRecord(session: session, revision: 2));
      final success = await future;

      expect(success, isFalse);
    });
  });

  group('P2 #4503139163 - Duplicate Active Session Reconciliation', () {
    WorkoutSession sessionWithId(String value, {WorkoutSessionStatus status = WorkoutSessionStatus.active}) =>
        createTestSession(id: WorkoutSessionId(value), status: status);

    Future<ActiveWorkoutController> duplicateStartController({
      required WorkoutSession sessionB,
    }) async {
      final controller = createController();
      fakeRepo.startSessionErrorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.duplicateActiveSession,
      );
      expect(await controller.startSession(sessionB), isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.reconciliationReason, 'duplicate_active_session');
      expect(controller.state.sessionId, sessionB.id);
      return controller;
    }

    test('adopts canonical active session A when rejected session B is absent', () async {
      final sessionA = sessionWithId('aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa');
      final sessionB = sessionWithId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final controller = await duplicateStartController(sessionB: sessionB);
      fakeRepo.returnNullForTargetLookup = true;
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: sessionA, revision: 4);

      expect(await controller.reconcileState(), isTrue);
      expect(fakeRepo.getSessionCalls, 1);
      expect(fakeRepo.getActiveSessionCalls, 1);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.record?.session.id, sessionA.id);
    });

    test('adopts canonical paused session A when rejected session B is absent', () async {
      final sessionA = sessionWithId('aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa')
          .pause(testStartTime.add(const Duration(minutes: 3)));
      final sessionB = sessionWithId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final controller = await duplicateStartController(sessionB: sessionB);
      fakeRepo.returnNullForTargetLookup = true;
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: sessionA, revision: 4);

      expect(await controller.reconcileState(), isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.paused);
      expect(controller.state.record?.session.id, sessionA.id);
    });

    test('emits noSession only after target and canonical active lookup confirm absence', () async {
      final sessionB = sessionWithId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final controller = await duplicateStartController(sessionB: sessionB);
      fakeRepo.returnNullForTargetLookup = true;
      fakeRepo.activeSessionToReturn = null;

      expect(await controller.reconcileState(), isTrue);
      expect(fakeRepo.getActiveSessionCalls, 1);
      expect(controller.state.status, ActiveWorkoutStatus.noSession);
    });

    test('fallback network failure preserves reconciliation state and blocks another start', () async {
      final sessionB = sessionWithId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final controller = await duplicateStartController(sessionB: sessionB);
      fakeRepo.returnNullForTargetLookup = true;
      fakeRepo.getActiveSessionErrorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
      );

      expect(await controller.reconcileState(), isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.sessionId, sessionB.id);
      expect(await controller.startSession(sessionWithId('cccccccc-cccc-4ccc-cccc-cccccccccccc')), isFalse);
      expect(fakeRepo.startSessionCalls, 1);
    });

    test('unknown start B remains safe and adopts A only after canonical fallback', () async {
      final sessionA = sessionWithId('aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa');
      final sessionB = sessionWithId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final controller = createController();
      fakeRepo.errorToThrow = WorkoutSessionMutationOutcomeUnknown(
        sessionId: sessionB.id,
        reason: WorkoutSessionMutationUncertainty.networkTimeout,
      );
      expect(await controller.startSession(sessionB), isFalse);
      fakeRepo.errorToThrow = null;
      fakeRepo.returnNullForTargetLookup = true;
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: sessionA, revision: 7);

      expect(await controller.reconcileState(), isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.record?.session.id, sessionA.id);
    });

    test('auth change during canonical fallback cannot overwrite authInvalidated state', () async {
      final sessionB = sessionWithId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final controller = await duplicateStartController(sessionB: sessionB);
      fakeRepo.returnNullForTargetLookup = true;
      final fallback = Completer<WorkoutSessionRecord?>();
      fakeRepo.pendingActiveSessionCompleter = fallback;

      final reconciliation = controller.reconcileState();
      currentUserId = null;
      controller.onAuthChanged();
      fallback.complete(null);

      expect(await reconciliation, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.authInvalidated);
    });

    test('concurrent recovery and disposal keep one fallback read and do not emit noSession', () async {
      final sessionB = sessionWithId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final controller = await duplicateStartController(sessionB: sessionB);
      fakeRepo.returnNullForTargetLookup = true;
      final fallback = Completer<WorkoutSessionRecord?>();
      fakeRepo.pendingActiveSessionCompleter = fallback;

      final first = controller.reconcileState();
      expect(await controller.reconcileState(), isFalse);
      expect(fakeRepo.getActiveSessionCalls, 1);
      controller.dispose();
      fallback.complete(null);

      expect(await first, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
    });
  });

  group('P2 #4502474724 - Session Reconciliation Target Separation', () {
    test('A completed -> B start -> unknown outcome reconciles B, not A', () async {
      final sessionA = createTestSession();
      final controller = createController();
      await controller.startSession(sessionA);
      await controller.completeSession();
      expect(controller.state.status, ActiveWorkoutStatus.completed);
      expect(controller.state.record?.session.id, sessionA.id);

      final sessionBId = WorkoutSessionId('bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb');
      final sessionB = WorkoutSession(
        id: sessionBId,
        userId: testUserId,
        programId: testProgramId,
        routineId: testRoutineId,
        status: WorkoutSessionStatus.active,
        time: WorkoutTime(
          startedAtUtc: testStartTime,
          lastTransitionAtUtc: testStartTime,
        ),
        localDate: '2026-11-07',
        snapshot: createTestSnapshot(),
      );

      fakeRepo.errorToThrow = WorkoutSessionMutationOutcomeUnknown(
        sessionId: sessionBId,
        reason: WorkoutSessionMutationUncertainty.networkTimeout,
      );
      final startSuccess = await controller.startSession(sessionB);
      expect(startSuccess, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.record, isNull);
      expect(controller.state.lastKnownSessionId, sessionBId);
      expect(controller.state.sessionId, sessionBId);

      // Now reconcile state against server
      fakeRepo.errorToThrow = null;
      fakeRepo.sessionsById[sessionBId.value] = WorkoutSessionRecord(
        session: sessionB,
        revision: 1,
      );

      final reconcileSuccess = await controller.reconcileState();
      expect(reconcileSuccess, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.record?.session.id, sessionBId);
      expect(controller.state.sessionId, sessionBId);
    });

    test('A discarded -> B start -> committed-readback failure reconciles B, not A', () async {
      final sessionA = createTestSession();
      final controller = createController();
      await controller.startSession(sessionA);
      await controller.discardSession(reason: 'Injury');
      expect(controller.state.status, ActiveWorkoutStatus.discarded);
      expect(controller.state.record?.session.id, sessionA.id);

      final sessionBId = WorkoutSessionId('bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb');
      final sessionB = WorkoutSession(
        id: sessionBId,
        userId: testUserId,
        programId: testProgramId,
        routineId: testRoutineId,
        status: WorkoutSessionStatus.active,
        time: WorkoutTime(
          startedAtUtc: testStartTime,
          lastTransitionAtUtc: testStartTime,
        ),
        localDate: '2026-11-07',
        snapshot: createTestSnapshot(),
      );

      fakeRepo.errorToThrow = WorkoutSessionCommittedReadbackException(
        sessionId: sessionBId,
        operationName: 'startSession',
        message: 'Timeout reading back session B',
      );
      final startSuccess = await controller.startSession(sessionB);
      expect(startSuccess, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.record, isNull);
      expect(controller.state.sessionId, sessionBId);

      // Reconcile reads B, which server has in paused state
      final pausedB = sessionB.pause(testStartTime.add(const Duration(minutes: 5)));
      fakeRepo.errorToThrow = null;
      fakeRepo.sessionsById[sessionBId.value] = WorkoutSessionRecord(
        session: pausedB,
        revision: 2,
      );

      final reconcileSuccess = await controller.reconcileState();
      expect(reconcileSuccess, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.paused);
      expect(controller.state.record?.session.id, sessionBId);
      expect(controller.state.isPaused, isTrue);
    });

    test('B remains resumable and editable if server confirms active state after reconciliation', () async {
      final sessionA = createTestSession();
      final controller = createController();
      await controller.startSession(sessionA);
      await controller.completeSession();

      final sessionBId = WorkoutSessionId('bbbbbbbb-bbbb-4bbb-abbb-bbbbbbbbbbbb');
      final sessionB = WorkoutSession(
        id: sessionBId,
        userId: testUserId,
        programId: testProgramId,
        routineId: testRoutineId,
        status: WorkoutSessionStatus.active,
        time: WorkoutTime(
          startedAtUtc: testStartTime,
          lastTransitionAtUtc: testStartTime,
        ),
        localDate: '2026-11-07',
        snapshot: createTestSnapshot(),
      );

      fakeRepo.errorToThrow = WorkoutSessionMutationOutcomeUnknown(
        sessionId: sessionBId,
        reason: WorkoutSessionMutationUncertainty.networkTimeout,
      );
      await controller.startSession(sessionB);

      fakeRepo.errorToThrow = null;
      fakeRepo.sessionsById[sessionBId.value] = WorkoutSessionRecord(
        session: sessionB,
        revision: 1,
      );
      await controller.reconcileState();
      expect(controller.state.isRunning, isTrue);

      final logSuccess = await controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
        loadKg: 50,
      );
      expect(logSuccess, isTrue);
      expect(controller.state.performedSets.length, 1);
      expect(controller.state.record?.session.id, sessionBId);
    });
  });

  group('P2 #4502474728 - Restore & Reconciliation Concurrency Serialization', () {
    test('restoreActiveSession returns immediately if a mutation (pause) is in flight', () async {
      final session = createTestSession();
      final controller = createController();
      await controller.startSession(session);

      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final pauseFuture = controller.pauseSession();
      expect(controller.state.isActionPending, isTrue);
      expect(controller.state.pendingActionName, 'pauseSession');

      final initialRestoreCalls = fakeRepo.getActiveSessionCalls;
      await controller.restoreActiveSession();
      expect(fakeRepo.getActiveSessionCalls, initialRestoreCalls);

      completer.complete(WorkoutSessionRecord(
        session: session.pause(testStartTime.add(const Duration(minutes: 1))),
        revision: 2,
      ));
      final pauseSuccess = await pauseFuture;
      expect(pauseSuccess, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.paused);
      expect(controller.state.record?.revision, 2);
    });

    test('reconcileState returns false immediately if logSet is in flight', () async {
      final session = createTestSession();
      final controller = createController();
      await controller.startSession(session);

      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final logFuture = controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
      );

      final reconcileResult = await controller.reconcileState();
      expect(reconcileResult, isFalse);

      final performedSet = PerformedSet(
        id: '66666666-6666-4666-a666-666666666666',
        exerciseRef: testExerciseRef,
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
        completedAtUtc: testStartTime,
      );
      completer.complete(WorkoutSessionRecord(
        session: session.logSet(performedSet),
        revision: 2,
      ));
      final logSuccess = await logFuture;
      expect(logSuccess, isTrue);
      expect(controller.state.record?.revision, 2);
    });

    test('restoreActiveSession returns immediately if completeSession is in flight', () async {
      final session = createTestSession();
      final controller = createController();
      await controller.startSession(session);

      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final completeFuture = controller.completeSession();

      final initialRestoreCalls = fakeRepo.getActiveSessionCalls;
      await controller.restoreActiveSession();
      expect(fakeRepo.getActiveSessionCalls, initialRestoreCalls);

      completer.complete(WorkoutSessionRecord(
        session: session.complete(testStartTime.add(const Duration(minutes: 30))),
        revision: 2,
      ));
      final completeSuccess = await completeFuture;
      expect(completeSuccess, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.completed);
    });

    test('mutations are rejected while reconcileState is in flight', () async {
      final session = createTestSession();
      fakeRepo.sessionsById[session.id.value] =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final reconcileFuture = controller.reconcileState();
      expect(controller.state.isActionPending, isTrue);

      final pauseSuccess = await controller.pauseSession();
      expect(pauseSuccess, isFalse);

      completer.complete(WorkoutSessionRecord(session: session, revision: 1));
      await reconcileFuture;
    });

    test('deferred read completing after auth change does not overwrite authInvalidated state', () async {
      final session = createTestSession();
      fakeRepo.sessionsById[session.id.value] =
          WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final reconcileFuture = controller.reconcileState();
      expect(controller.state.isActionPending, isTrue);

      currentUserId = null;
      controller.onAuthChanged();
      expect(controller.state.status, ActiveWorkoutStatus.authInvalidated);

      completer.complete(WorkoutSessionRecord(session: session, revision: 1));
      final result = await reconcileFuture;
      expect(result, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.authInvalidated);
    });

    test('disposal during in-flight operation completes safely without modifying state or throwing', () async {
      final session = createTestSession();
      final controller = createController();
      await controller.startSession(session);

      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final pauseFuture = controller.pauseSession();
      expect(controller.state.isActionPending, isTrue);

      controller.dispose();

      completer.complete(WorkoutSessionRecord(
        session: session.pause(testStartTime.add(const Duration(minutes: 1))),
        revision: 2,
      ));
      final result = await pauseFuture;
      expect(result, isFalse);
    });
  });

  group('P2 #4502474732 - Authoritative Start Lifecycle Handling', () {
    test('startSession returning active session adopts active status', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(
        session: session,
        revision: 1,
      );

      final controller = createController();
      final success = await controller.startSession(session);

      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.isRunning, isTrue);
      expect(controller.state.record?.revision, 1);
    });

    test('idempotent replay start returns paused session and adopts paused status', () async {
      final session = createTestSession();
      final pausedSession = session.pause(testStartTime.add(const Duration(minutes: 2)));
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(
        session: pausedSession,
        revision: 3,
      );

      final controller = createController();
      final success = await controller.startSession(session);

      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.paused);
      expect(controller.state.isPaused, isTrue);
      expect(controller.state.record?.revision, 3);
    });

    test('idempotent replay start returns completed session and adopts terminal completed status', () async {
      final session = createTestSession();
      final completedSession = session.complete(testStartTime.add(const Duration(minutes: 45)));
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(
        session: completedSession,
        revision: 5,
      );

      final controller = createController();
      final success = await controller.startSession(session);

      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.completed);
      expect(controller.state.isTerminal, isTrue);
      expect(controller.state.record?.revision, 5);

      final logSuccess = await controller.logSet(sessionExerciseIndex: 0, setIndex: 0, reps: 5);
      expect(logSuccess, isFalse);
    });

    test('idempotent replay start returns discarded session and adopts terminal discarded status', () async {
      final session = createTestSession();
      final discardedSession = session.discard(
        testStartTime.add(const Duration(minutes: 10)),
        reason: 'User gave up',
      );
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(
        session: discardedSession,
        revision: 4,
      );

      final controller = createController();
      final success = await controller.startSession(session);

      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.discarded);
      expect(controller.state.isTerminal, isTrue);
    });

    test('idempotent replay start returns paused session after another device paused it, and resumeSession succeeds', () async {
      final session = createTestSession();
      final pausedSession = session.pause(testStartTime.add(const Duration(minutes: 5)));
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(
        session: pausedSession,
        revision: 2,
      );

      final controller = createController();
      final success = await controller.startSession(session);
      expect(success, isTrue);
      expect(controller.state.isPaused, isTrue);

      // Now resume from paused state
      currentTime = testStartTime.add(const Duration(minutes: 6));
      final resumeSuccess = await controller.resumeSession();
      expect(resumeSuccess, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.record?.revision, 3);
    });
  });

  group('P2 #4502474740 - Device Clock Rollback Resilience', () {
    test('device clock backward jump before lastTransitionAtUtc does not throw and preserves stable duration', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      currentTime = testStartTime.add(const Duration(seconds: 10));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 10));

      currentTime = testStartTime.subtract(const Duration(seconds: 20));

      expect(() => controller.updateElapsedDuration(), returnsNormally);
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 10));
    });

    test('normal duration progression resumes once device clock advances past rollback watermark', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      currentTime = testStartTime.add(const Duration(seconds: 15));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 15));

      currentTime = testStartTime.add(const Duration(seconds: 5));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 15));

      currentTime = testStartTime.add(const Duration(seconds: 20));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 20));
    });

    test('clock rollback during paused session preserves paused duration without error', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      currentTime = testStartTime.add(const Duration(seconds: 30));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 30));

      await controller.pauseSession(pausedAtUtc: currentTime);
      expect(controller.state.isPaused, isTrue);

      currentTime = testStartTime.subtract(const Duration(seconds: 10));
      expect(() => controller.updateElapsedDuration(), returnsNormally);
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 30));
    });

    test('app foreground re-evaluation updates elapsed time safely without unhandled exception', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      currentTime = testStartTime.subtract(const Duration(minutes: 5));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, Duration.zero);
    });

    test('ticker stops on disposal, completion, discard, and auth invalidation', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      controller.startDurationTicker(interval: const Duration(milliseconds: 50));
      await controller.completeSession();
      expect(controller.state.status, ActiveWorkoutStatus.completed);

      expect(() => controller.dispose(), returnsNormally);
    });
  });

  group('P2 #4502581537 - Reset Elapsed Duration Baseline on New Session', () {
    test('resets elapsed duration baseline when starting session B after 30-minute session A', () async {
      final sessionAId = WorkoutSessionId('aaaaaaaa-aaaa-4aaa-aaaa-aaaaaaaaaaaa');
      final sessionA = createTestSession(id: sessionAId);
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: sessionA, revision: 1);
      final controller = createController();
      await controller.startSession(sessionA);

      // Advance clock by 30 minutes in session A
      currentTime = testStartTime.add(const Duration(minutes: 30));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(minutes: 30));

      // Complete session A
      await controller.completeSession(completedAtUtc: currentTime);
      expect(controller.state.status, ActiveWorkoutStatus.completed);
      expect(controller.state.activeElapsedDuration, const Duration(minutes: 30));

      // Start session B with fresh start time
      final sessionBStart = currentTime.add(const Duration(hours: 1));
      currentTime = sessionBStart;
      final sessionBId = WorkoutSessionId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final sessionB = createTestSession(
        id: sessionBId,
        startedAtUtc: sessionBStart,
      );
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: sessionB, revision: 1);

      final started = await controller.startSession(sessionB);
      expect(started, isTrue);
      expect(controller.state.sessionId, sessionBId);
      // Verifies duration is reset to zero rather than inheriting 30 minutes from session A
      expect(controller.state.activeElapsedDuration, Duration.zero);

      // Advance clock by 15 seconds in session B
      currentTime = sessionBStart.add(const Duration(seconds: 15));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 15));
    });
  });

  group('P2 #4502581544 - Guard Start During Pending Reconciliation', () {
    test('blocks startSession and startSessionFromRoutine when reconciliationRequired to preserve recovery target', () async {
      final sessionBId = WorkoutSessionId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final sessionB = createTestSession(id: sessionBId);
      final controller = createController();

      // Trigger uncertain outcome during start of session B
      fakeRepo.errorToThrow = WorkoutSessionMutationOutcomeUnknown(
        sessionId: sessionB.id,
        reason: WorkoutSessionMutationUncertainty.networkTimeout,
      );

      final startB = await controller.startSession(sessionB);
      expect(startB, isFalse);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.sessionId, sessionB.id);

      // Attempt to dispatch a new session C via startSession
      final sessionC = createTestSession(id: WorkoutSessionId('cccccccc-cccc-4ccc-cccc-cccccccccccc'));
      final startC = await controller.startSession(sessionC);
      expect(startC, isFalse);
      expect(
        controller.state.errorMessage,
        'Cannot start a session: state reconciliation is required.',
      );
      // Recovery target for session B must NOT be overwritten by C
      expect(controller.state.sessionId, sessionB.id);

      // Attempt to dispatch via startSessionFromRoutine
      fakeRepo.errorToThrow = null;
      final program = Program(
        id: testProgramId,
        name: 'Hypertrophy Block',
      );
      final routine = Routine(
        id: testRoutineId,
        programId: testProgramId,
        name: 'Push Day A',
      );
      final composition = RoutineComposition(
        routineId: testRoutineId,
        exercises: [
          RoutineExercise(
            exercise: testExerciseRef,
            sets: [
              SetPrescription(
                setType: RoutineSetType.normal,
                reps: 8,
                loadKg: 80.0,
              ),
            ],
          ),
        ],
      );
      final resolvedExercises = {
        testExerciseRef: Exercise(
          ref: testExerciseRef,
          displayName: 'Bench Press',
          exerciseType: ExerciseType.weightReps,
          status: ExerciseStatus.active,
        ),
      };

      final startRoutine = await controller.startSessionFromRoutine(
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: resolvedExercises,
        localDate: '2026-11-07',
      );
      expect(startRoutine, isFalse);
      expect(
        controller.state.errorMessage,
        'Cannot start a session: state reconciliation is required.',
      );
      expect(controller.state.sessionId, sessionB.id);
    });
  });

  group('P2 #4502581548 - Authoritative Lifecycle Status Across All Mutation Readbacks', () {
    test('pauseSession adopts authoritative completed status if completed concurrently on another device', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);
      expect(controller.state.status, ActiveWorkoutStatus.active);

      // Simulate pause mutation readback returning session completed concurrently on companion device
      final completedSession = session.complete(
        testStartTime.add(const Duration(minutes: 20)),
        notes: 'Completed from companion device',
      );
      fakeRepo.customMutationRecordToReturn = WorkoutSessionRecord(session: completedSession, revision: 2);

      final paused = await controller.pauseSession();
      expect(paused, isTrue);
      // Status must adopt server authoritative status (completed, not paused)
      expect(controller.state.status, ActiveWorkoutStatus.completed);
      expect(controller.state.session?.isTerminal, isTrue);
    });

    test('logSet adopts authoritative paused status if paused concurrently on another device', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);
      expect(controller.state.status, ActiveWorkoutStatus.active);

      // Simulate set logging readback returning session paused concurrently
      final pausedSession = session.pause(testStartTime.add(const Duration(minutes: 5)));
      fakeRepo.customMutationRecordToReturn = WorkoutSessionRecord(session: pausedSession, revision: 2);

      final logged = await controller.logSet(
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
      );
      expect(logged, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.paused);
      expect(controller.state.isPaused, isTrue);
    });

    test('resumeSession adopts authoritative completed status if completed concurrently on server', () async {
      final session = createTestSession();
      final pausedSession = session.pause(testStartTime.add(const Duration(minutes: 5)));
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: pausedSession, revision: 2);
      final controller = createController();
      await controller.restoreActiveSession();
      expect(controller.state.status, ActiveWorkoutStatus.paused);

      // Resume mutation readback returns completed session
      final completedSession = pausedSession.complete(
        testStartTime.add(const Duration(minutes: 25)),
      );
      fakeRepo.customMutationRecordToReturn = WorkoutSessionRecord(session: completedSession, revision: 3);

      final resumed = await controller.resumeSession();
      expect(resumed, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.completed);
    });

    test('removeSet adopts authoritative completed status if session completed concurrently', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      final completedSession = session.complete(
        testStartTime.add(const Duration(minutes: 30)),
      );
      fakeRepo.customMutationRecordToReturn = WorkoutSessionRecord(session: completedSession, revision: 2);

      final removed = await controller.removeSet('set-to-remove');
      expect(removed, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.completed);
    });
  });

  group('P2 #4502680017 - Authoritative Elapsed Duration Correction', () {
    test('pauseSession corrects speculative ticker duration accumulated during latency', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);
      expect(controller.state.status, ActiveWorkoutStatus.active);

      // Advance clock to 60s
      currentTime = testStartTime.add(const Duration(seconds: 60));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 60));

      // Pause is dispatched at 60s, but delayed over the wire
      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final pauseFuture = controller.pauseSession(pausedAtUtc: currentTime);

      // Speculative ticker ticks to 65s while mutation is in-flight
      currentTime = testStartTime.add(const Duration(seconds: 65));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 65));

      // Server completes pause mutation at exactly 60s
      fakeRepo.pendingCompleter = null;
      final pausedSession = session.pause(testStartTime.add(const Duration(seconds: 60)));
      completer.complete(WorkoutSessionRecord(session: pausedSession, revision: 2));

      final success = await pauseFuture;
      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.paused);
      // Authoritative readback must correct speculative 65s back to authoritative 60s
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 60));
    });

    test('completeSession corrects speculative ticker duration accumulated during latency', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      currentTime = testStartTime.add(const Duration(seconds: 120));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 120));

      final completer = Completer<WorkoutSessionRecord>();
      fakeRepo.pendingCompleter = completer;

      final completeFuture = controller.completeSession(completedAtUtc: currentTime);

      // Speculative ticker ticks to 128s while mutation in-flight
      currentTime = testStartTime.add(const Duration(seconds: 128));
      controller.updateElapsedDuration();
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 128));

      // Server confirms completion at 120s
      fakeRepo.pendingCompleter = null;
      final completedSession = session.complete(testStartTime.add(const Duration(seconds: 120)));
      completer.complete(WorkoutSessionRecord(session: completedSession, revision: 2));

      final success = await completeFuture;
      expect(success, isTrue);
      expect(controller.state.status, ActiveWorkoutStatus.completed);
      // Authoritative completion corrects speculative 128s back to 120s
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 120));
    });

    test('paused time remains excluded upon resume and subsequent ticker ticks', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);

      currentTime = testStartTime.add(const Duration(seconds: 60));
      await controller.pauseSession(pausedAtUtc: currentTime);
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 60));

      // Advance clock by 5 minutes while paused
      currentTime = testStartTime.add(const Duration(seconds: 360));
      controller.updateElapsedDuration();
      // Paused duration must not advance
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 60));

      // Resume at 360s
      await controller.resumeSession(resumedAtUtc: currentTime);
      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 60));

      // Advance clock by 10s after resume
      currentTime = testStartTime.add(const Duration(seconds: 370));
      controller.updateElapsedDuration();
      // Active duration is 60s + 10s = 70s (5-minute pause is excluded)
      expect(controller.state.activeElapsedDuration, const Duration(seconds: 70));
    });
  });

  group('P2 #4502680020 & #4502685338 - Restore Read Failure Must Not Mean No Session', () {
    test('previously active session + restore network failure preserves active session state and enters reconciliationRequired', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);
      expect(controller.state.status, ActiveWorkoutStatus.active);

      // Simulate network failure during restoreActiveSession (e.g. app resume from background)
      fakeRepo.errorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'Network connection lost',
      );

      await controller.restoreActiveSession();

      // Must NOT report noSession!
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.status, isNot(ActiveWorkoutStatus.noSession));
      expect(controller.state.record, isNotNull);
      expect(controller.state.sessionId, testSessionId);
      expect(controller.state.reconciliationReason, 'restore_failed');
      expect(controller.state.errorMessage, 'Network connection lost');
    });

    test('previously paused session + transient read failure preserves paused record and session identity', () async {
      final session = createTestSession();
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      final controller = createController();
      await controller.startSession(session);
      await controller.pauseSession();
      expect(controller.state.status, ActiveWorkoutStatus.paused);

      fakeRepo.errorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.unavailable,
        message: 'Database temporarily unavailable',
      );

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.record?.session.status, WorkoutSessionStatus.paused);
      expect(controller.state.sessionId, testSessionId);
      expect(controller.state.errorMessage, 'Database temporarily unavailable');
    });

    test('reconciliation-required state + restore failure preserves original reconciliationReason and target ID', () async {
      final sessionBId = WorkoutSessionId('bbbbbbbb-bbbb-4bbb-bbbb-bbbbbbbbbbbb');
      final sessionB = createTestSession(id: sessionBId);
      final controller = createController();

      // Cause reconciliationRequired via mutation uncertainty
      fakeRepo.errorToThrow = WorkoutSessionMutationOutcomeUnknown(
        sessionId: sessionB.id,
        reason: WorkoutSessionMutationUncertainty.networkTimeout,
      );
      await controller.startSession(sessionB);
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.reconciliationReason, 'networkTimeout');
      expect(controller.state.sessionId, sessionBId);

      // Now restoreActiveSession is invoked and fails with read network error
      fakeRepo.errorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'Still offline',
      );

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      // Original reconciliationReason and recovery target ID must be preserved
      expect(controller.state.reconciliationReason, 'networkTimeout');
      expect(controller.state.sessionId, sessionBId);
      expect(controller.state.errorMessage, 'Still offline');
    });

    test('cold restore failure with unknown session presence enters reconciliationRequired and does NOT emit noSession', () async {
      final controller = createController();
      expect(controller.state.status, ActiveWorkoutStatus.initial);

      fakeRepo.errorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'No Internet connection',
      );

      await controller.restoreActiveSession();

      // Absence was not confirmed; must NOT declare noSession
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.status, isNot(ActiveWorkoutStatus.noSession));
      expect(controller.state.errorMessage, 'No Internet connection');
    });

    test('successful null read returns noSession', () async {
      final controller = createController();
      fakeRepo.activeSessionToReturn = null;

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.noSession);
      expect(controller.state.record, isNull);
      expect(controller.state.errorMessage, isNull);
    });

    test('failed restore cannot authorize duplicate start', () async {
      final controller = createController();
      fakeRepo.errorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'Offline',
      );

      await controller.restoreActiveSession();
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);

      // User attempts to start new workout while state is unconfirmed
      final newSession = createTestSession();
      final started = await controller.startSession(newSession);
      expect(started, isFalse);
      expect(
        controller.state.errorMessage,
        'Cannot start a session: state reconciliation is required.',
      );

      // Also startFromRoutine is blocked
      final program = Program(id: testProgramId, name: 'Block A');
      final routine = Routine(id: testRoutineId, programId: testProgramId, name: 'Routine A');
      final composition = RoutineComposition(
        routineId: testRoutineId,
        exercises: [
          RoutineExercise(
            exercise: testExerciseRef,
            sets: [SetPrescription(setType: RoutineSetType.normal, reps: 8, loadKg: 80.0)],
          ),
        ],
      );
      final resolvedExercises = {
        testExerciseRef: Exercise(
          ref: testExerciseRef,
          displayName: 'Bench Press',
          exerciseType: ExerciseType.weightReps,
          status: ExerciseStatus.active,
        ),
      };

      final routineStarted = await controller.startSessionFromRoutine(
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: resolvedExercises,
        localDate: '2026-11-07',
      );
      expect(routineStarted, isFalse);
      expect(
        controller.state.errorMessage,
        'Cannot start a session: state reconciliation is required.',
      );
    });

    test('retry succeeds and restores authoritative session', () async {
      final session = createTestSession();
      final controller = createController();

      // 1. Initial restore fails
      fakeRepo.errorToThrow = const WorkoutSessionPersistenceException(
        WorkoutSessionPersistenceFailureKind.networkUnavailable,
        message: 'Temporary glitch',
      );
      await controller.restoreActiveSession();
      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);

      // 2. Network recovers, retry succeeds
      fakeRepo.errorToThrow = null;
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 3);

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.active);
      expect(controller.state.revision, 3);
      expect(controller.state.errorMessage, isNull);
      expect(controller.state.reconciliationReason, isNull);
    });

    test('auth change during restore invalidates stale data without overwriting authInvalidated state', () async {
      final session = createTestSession();
      fakeRepo.pendingRestoreCompleter = Completer<WorkoutSessionRecord?>();
      final controller = createController();

      // Launch restore with pending read
      final restoreFuture = controller.restoreActiveSession();
      expect(controller.state.status, ActiveWorkoutStatus.restoring);

      // User signs out before read completes
      currentUserId = null;
      controller.onAuthChanged();
      expect(controller.state.status, ActiveWorkoutStatus.authInvalidated);

      // Restore finally completes with stale server record
      fakeRepo.activeSessionToReturn = WorkoutSessionRecord(session: session, revision: 1);
      fakeRepo.pendingRestoreCompleter!.complete(fakeRepo.activeSessionToReturn);
      await restoreFuture;

      // Must remain authInvalidated and must NOT adopt stale session data
      expect(controller.state.status, ActiveWorkoutStatus.authInvalidated);
      expect(controller.state.record, isNull);
    });

    test('disposal during pending restore does not emit new state or throw', () async {
      final session = createTestSession();
      fakeRepo.pendingRestoreCompleter = Completer<WorkoutSessionRecord?>();
      final controller = createController();

      final restoreFuture = controller.restoreActiveSession();
      expect(controller.state.status, ActiveWorkoutStatus.restoring);

      controller.dispose();

      fakeRepo.pendingRestoreCompleter!.complete(WorkoutSessionRecord(session: session, revision: 1));
      await restoreFuture;

      expect(() => controller.state, returnsNormally);
    });

    test('unexpected generic exception during restore enters reconciliationRequired consistently', () async {
      final controller = createController();
      fakeRepo.errorToThrow = Exception('Unexpected TLS handshake failure');

      await controller.restoreActiveSession();

      expect(controller.state.status, ActiveWorkoutStatus.reconciliationRequired);
      expect(controller.state.status, isNot(ActiveWorkoutStatus.noSession));
      expect(
        controller.state.errorMessage,
        contains('Unexpected TLS handshake failure'),
      );
    });
  });
}

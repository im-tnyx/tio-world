import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

final class _FakeWorkoutSessionRepository implements WorkoutSessionRepository {
  WorkoutSessionRecord? activeSessionToReturn;
  final Map<String, WorkoutSessionRecord> sessionsById = {};
  Exception? errorToThrow;
  Completer<WorkoutSessionRecord>? pendingCompleter;
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
    if (errorToThrow != null) throw errorToThrow!;
    return activeSessionToReturn;
  }

  @override
  Future<WorkoutSessionRecord?> getSession(WorkoutSessionId sessionId) async {
    getSessionCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    return sessionsById[sessionId.value] ?? activeSessionToReturn;
  }

  @override
  Future<WorkoutSessionRecord> startSession(WorkoutSession session) async {
    startSessionCalls++;
    if (errorToThrow != null) throw errorToThrow!;
    if (pendingCompleter != null) return pendingCompleter!.future;
    final record = WorkoutSessionRecord(session: session, revision: 1);
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

  WorkoutSessionSnapshot createTestSnapshot() => WorkoutSessionSnapshot(
        routineId: testRoutineId,
        routineName: 'Push Day A',
        programId: testProgramId,
        capturedAtUtc: testStartTime,
        exercises: [
          SessionExerciseSnapshot(
            exerciseRef: const CatalogExerciseRef('bench_press'),
            displayName: 'Bench Press',
            exerciseType: ExerciseType.weightReps,
            occurrenceIndex: 0,
            prescribedSets: const [
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
    WorkoutSessionStatus status = WorkoutSessionStatus.active,
    DateTime? pausedAt,
    int pausedDurationUs = 0,
    List<PerformedSet> sets = const [],
    String? notes,
    String? discardReason,
  }) =>
      WorkoutSession(
        id: testSessionId,
        userId: testUserId,
        programId: testProgramId,
        routineId: testRoutineId,
        status: status,
        time: WorkoutTime(
          startedAtUtc: testStartTime,
          pausedAtUtc: pausedAt,
          accumulatedPausedDuration: Duration(microseconds: pausedDurationUs),
          completedAtUtc: status.isTerminal ? pausedAt ?? testStartTime : null,
          lastTransitionAtUtc: pausedAt ?? testStartTime,
        ),
        localDate: '2026-11-07',
        snapshot: createTestSnapshot(),
        performedSets: sets,
        notes: notes,
        discardReason: discardReason,
      );

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
        userId: testUserId,
        name: 'Hypertrophy Block',
      );
      final routine = Routine(
        id: testRoutineId,
        programId: testProgramId,
        name: 'Push Day A',
      );
      final composition = RoutineComposition(
        routineId: testRoutineId,
        programId: testProgramId,
        entries: [
          RoutineCompositionEntry(
            id: '66666666-6666-4666-a666-666666666666',
            exerciseRef: const CatalogExerciseRef('bench_press'),
            orderIndex: 0,
            sets: const [
              PrescribedSetEntry(
                id: '77777777-7777-4777-a777-777777777777',
                prescription: SetPrescription(
                  setType: RoutineSetType.normal,
                  reps: 8,
                  loadKg: 80.0,
                ),
              ),
            ],
          ),
        ],
      );
      final resolvedExercises = {
        const CatalogExerciseRef('bench_press'): Exercise(
          ref: const CatalogExerciseRef('bench_press'),
          name: 'Bench Press',
          exerciseType: ExerciseType.weightReps,
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
        userId: testUserId,
        name: 'Hypertrophy Block',
      );
      final routine = Routine(
        id: testRoutineId,
        programId: testProgramId,
        name: 'Empty Routine',
      );
      final emptyComposition = RoutineComposition(
        routineId: testRoutineId,
        programId: testProgramId,
        entries: const [],
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
        exerciseRef: const CatalogExerciseRef('bench_press'),
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
}

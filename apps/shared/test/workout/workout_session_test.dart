import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const sessionUuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';
  const userUuid = '01920f3e-7c4a-7b2d-9e1f-2a3b4c5d6e7f';
  const programUuid = 'c232ab00-9414-11ec-b3c8-9f6bdeced846';
  const routineUuid = 'd89b3f4a-7c2d-4e5f-9a1b-3c4d5e6f7a8b';
  const setUuid = 'a1b2c3d4-e5f6-4a1b-8c2d-3e4f5a6b7c8d';

  final t0 = DateTime.utc(2026, 11, 5, 10, 0, 0);
  final t1 = DateTime.utc(2026, 11, 5, 10, 15, 0);
  final t2 = DateTime.utc(2026, 11, 5, 10, 20, 0);
  final t3 = DateTime.utc(2026, 11, 5, 11, 0, 0);

  final snapshot = WorkoutSessionSnapshot(
    routineId: RoutineId(routineUuid),
    routineName: 'Upper Body A',
    programId: ProgramId(programUuid),
    capturedAtUtc: t0,
    exercises: [
      SessionExerciseSnapshot(
        exerciseRef: ExerciseRef.catalog('ex_barbell_bench_press'),
        displayName: 'Bench Press',
        exerciseType: ExerciseType.weightReps,
        occurrenceIndex: 0,
        prescribedSets: [SetPrescription(reps: 8, loadKg: 70)],
      ),
    ],
  );

  group('WorkoutSession', () {
    test('starts in active state with aligned WorkoutTime', () {
      final session = WorkoutSession.start(
        id: WorkoutSessionId(sessionUuid),
        userId: userUuid,
        programId: ProgramId(programUuid),
        routineId: RoutineId(routineUuid),
        snapshot: snapshot,
        localDate: '2026-11-05',
        startedAtUtc: t0,
      );

      expect(session.status, WorkoutSessionStatus.active);
      expect(session.isTerminal, isFalse);
      expect(session.time.isPaused, isFalse);
      expect(session.time.startedAtUtc, t0);
      expect(session.performedSets, isEmpty);
      expect(session.localDate, '2026-11-05');
      expect(session.discardReason, isNull);
    });

    test('validates localDate as a valid Gregorian YYYY-MM-DD date', () {
      WorkoutSession createWithDate(String date) => WorkoutSession.start(
            id: WorkoutSessionId(sessionUuid),
            userId: userUuid,
            programId: ProgramId(programUuid),
            routineId: RoutineId(routineUuid),
            snapshot: snapshot,
            localDate: date,
            startedAtUtc: t0,
          );

      expect(() => createWithDate('2026-13-01'), throwsArgumentError); // Month 13
      expect(() => createWithDate('2026-02-29'), throwsArgumentError); // 2026 not leap year
      expect(() => createWithDate('2026/11/05'), throwsArgumentError);
      expect(() => createWithDate('invalid'), throwsArgumentError);
    });

    test('enforces that snapshot matches session routineId and programId', () {
      final wrongSnapshot = WorkoutSessionSnapshot(
        routineId: RoutineId('00000000-0000-4000-8000-000000000001'),
        routineName: 'Different Routine',
        programId: ProgramId(programUuid),
        capturedAtUtc: t0,
      );

      expect(
        () => WorkoutSession.start(
          id: WorkoutSessionId(sessionUuid),
          userId: userUuid,
          programId: ProgramId(programUuid),
          routineId: RoutineId(routineUuid),
          snapshot: wrongSnapshot,
          localDate: '2026-11-05',
          startedAtUtc: t0,
        ),
        throwsArgumentError,
      );
    });

    test('performs legal lifecycle transitions: pause -> resume -> complete', () {
      final active = WorkoutSession.start(
        id: WorkoutSessionId(sessionUuid),
        userId: userUuid,
        programId: ProgramId(programUuid),
        routineId: RoutineId(routineUuid),
        snapshot: snapshot,
        localDate: '2026-11-05',
        startedAtUtc: t0,
      );

      final paused = active.pause(t1);
      expect(paused.status, WorkoutSessionStatus.paused);
      expect(paused.time.isPaused, isTrue);

      final resumed = paused.resume(t2);
      expect(resumed.status, WorkoutSessionStatus.active);
      expect(resumed.time.isPaused, isFalse);

      final completed = resumed.complete(t3, notes: 'Great pump');
      expect(completed.status, WorkoutSessionStatus.completed);
      expect(completed.isTerminal, isTrue);
      expect(completed.notes, 'Great pump');
      expect(completed.time.isCompleted, isTrue);
      expect(
        completed.time.elapsedActiveDuration(t3),
        const Duration(minutes: 55), // 60 min - 5 min pause
      );
    });

    test('performs discard with mandatory reason', () {
      final active = WorkoutSession.start(
        id: WorkoutSessionId(sessionUuid),
        userId: userUuid,
        programId: ProgramId(programUuid),
        routineId: RoutineId(routineUuid),
        snapshot: snapshot,
        localDate: '2026-11-05',
        startedAtUtc: t0,
      );

      final discarded = active.discard(t1, reason: 'Gym closed early');
      expect(discarded.status, WorkoutSessionStatus.discarded);
      expect(discarded.isTerminal, isTrue);
      expect(discarded.discardReason, 'Gym closed early');

      expect(
        () => active.discard(t1, reason: '   '),
        throwsArgumentError,
      );
    });

    test('blocks transitions and set mutations on terminal sessions', () {
      final completed = WorkoutSession.start(
        id: WorkoutSessionId(sessionUuid),
        userId: userUuid,
        programId: ProgramId(programUuid),
        routineId: RoutineId(routineUuid),
        snapshot: snapshot,
        localDate: '2026-11-05',
        startedAtUtc: t0,
      ).complete(t1);

      expect(() => completed.pause(t2), throwsStateError);
      expect(() => completed.resume(t2), throwsStateError);
      expect(() => completed.complete(t2), throwsStateError);
      expect(() => completed.discard(t2, reason: 'test'), throwsStateError);

      final testSet = PerformedSet(
        id: setUuid,
        exerciseRef: ExerciseRef.catalog('ex_barbell_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
        loadKg: 70,
      );

      expect(() => completed.logSet(testSet), throwsStateError);
      expect(() => completed.removeSet(setUuid), throwsStateError);
    });

    test('logs and updates performed sets with defensive copying', () {
      var session = WorkoutSession.start(
        id: WorkoutSessionId(sessionUuid),
        userId: userUuid,
        programId: ProgramId(programUuid),
        routineId: RoutineId(routineUuid),
        snapshot: snapshot,
        localDate: '2026-11-05',
        startedAtUtc: t0,
      );

      final set1 = PerformedSet(
        id: setUuid,
        exerciseRef: ExerciseRef.catalog('ex_barbell_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 8,
        loadKg: 70,
      );

      session = session.logSet(set1);
      expect(session.performedSets, hasLength(1));
      expect(session.performedSets[0].reps, 8);

      // Updating the set with new values (same ID)
      final set1Updated = PerformedSet(
        id: setUuid,
        exerciseRef: ExerciseRef.catalog('ex_barbell_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 0,
        reps: 10,
        loadKg: 70,
      );

      session = session.logSet(set1Updated);
      expect(session.performedSets, hasLength(1));
      expect(session.performedSets[0].reps, 10);

      // Adding a second set
      final set2 = PerformedSet(
        id: 'c232ab00-9414-11ec-b3c8-9f6bdeced846',
        exerciseRef: ExerciseRef.catalog('ex_barbell_bench_press'),
        sessionExerciseIndex: 0,
        setIndex: 1,
        reps: 8,
        loadKg: 75,
      );

      session = session.logSet(set2);
      expect(session.performedSets, hasLength(2));

      // Removing set1
      session = session.removeSet(setUuid);
      expect(session.performedSets, hasLength(1));
      expect(session.performedSets[0].id, 'c232ab00-9414-11ec-b3c8-9f6bdeced846');
    });

    test('implements value equality', () {
      final a = WorkoutSession.start(
        id: WorkoutSessionId(sessionUuid),
        userId: userUuid,
        programId: ProgramId(programUuid),
        routineId: RoutineId(routineUuid),
        snapshot: snapshot,
        localDate: '2026-11-05',
        startedAtUtc: t0,
      );
      final b = WorkoutSession.start(
        id: WorkoutSessionId(sessionUuid),
        userId: userUuid,
        programId: ProgramId(programUuid),
        routineId: RoutineId(routineUuid),
        snapshot: snapshot,
        localDate: '2026-11-05',
        startedAtUtc: t0,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}

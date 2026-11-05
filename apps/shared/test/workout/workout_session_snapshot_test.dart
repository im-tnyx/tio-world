import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const routineUuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';
  const programUuid = '01920f3e-7c4a-7b2d-9e1f-2a3b4c5d6e7f';
  final exBench = ExerciseRef.catalog('ex_barbell_bench_press');
  final exSquat = ExerciseRef.catalog('ex_barbell_back_squat');
  final nowUtc = DateTime.utc(2026, 11, 5, 10, 0, 0);

  group('SessionExerciseSnapshot', () {
    test('defensively copies prescribed sets and preserves immutability', () {
      final sourceSets = [
        SetPrescription(reps: 10, loadKg: 60),
        SetPrescription(reps: 8, loadKg: 70),
      ];

      final snapshot = SessionExerciseSnapshot(
        exerciseRef: exBench,
        displayName: 'Barbell Bench Press',
        exerciseType: ExerciseType.weightReps,
        occurrenceIndex: 0,
        prescribedSets: sourceSets,
      );

      sourceSets.clear();
      expect(snapshot.prescribedSets, hasLength(2));
      expect(snapshot.prescribedSets[0].reps, 10);
      expect(
        () => snapshot.prescribedSets.add(SetPrescription(reps: 6)),
        throwsUnsupportedError,
      );
    });

    test('rejects blank display name and negative occurrence index', () {
      expect(
        () => SessionExerciseSnapshot(
          exerciseRef: exBench,
          displayName: '   ',
          occurrenceIndex: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => SessionExerciseSnapshot(
          exerciseRef: exBench,
          displayName: 'Bench Press',
          occurrenceIndex: -1,
        ),
        throwsArgumentError,
      );
    });

    test('implements value equality', () {
      final a = SessionExerciseSnapshot(
        exerciseRef: exBench,
        displayName: 'Bench Press',
        occurrenceIndex: 0,
        prescribedSets: [SetPrescription(reps: 8)],
      );
      final b = SessionExerciseSnapshot(
        exerciseRef: exBench,
        displayName: 'Bench Press',
        occurrenceIndex: 0,
        prescribedSets: [SetPrescription(reps: 8)],
      );
      final c = SessionExerciseSnapshot(
        exerciseRef: exBench,
        displayName: 'Bench Press',
        occurrenceIndex: 1, // different occurrence
        prescribedSets: [SetPrescription(reps: 8)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('WorkoutSessionSnapshot', () {
    test('defensively copies exercise snapshots and preserves immutability', () {
      final sourceExercises = [
        SessionExerciseSnapshot(
          exerciseRef: exBench,
          displayName: 'Bench Press',
          occurrenceIndex: 0,
        ),
        SessionExerciseSnapshot(
          exerciseRef: exSquat,
          displayName: 'Back Squat',
          occurrenceIndex: 1,
        ),
      ];

      final snapshot = WorkoutSessionSnapshot(
        routineId: RoutineId(routineUuid),
        routineName: 'Push / Legs Day',
        programId: ProgramId(programUuid),
        capturedAtUtc: nowUtc,
        exercises: sourceExercises,
      );

      sourceExercises.clear();
      expect(snapshot.exercises, hasLength(2));
      expect(
        () => snapshot.exercises.add(
          SessionExerciseSnapshot(
            exerciseRef: exBench,
            displayName: 'Bench Press 2',
            occurrenceIndex: 2,
          ),
        ),
        throwsUnsupportedError,
      );
    });

    test('enforces UTC timestamp and non-blank routine name', () {
      final local = DateTime(2026, 11, 5, 10, 0, 0);
      expect(
        () => WorkoutSessionSnapshot(
          routineId: RoutineId(routineUuid),
          routineName: 'Chest Day',
          programId: ProgramId(programUuid),
          capturedAtUtc: local,
        ),
        throwsArgumentError,
      );
      expect(
        () => WorkoutSessionSnapshot(
          routineId: RoutineId(routineUuid),
          routineName: '   ',
          programId: ProgramId(programUuid),
          capturedAtUtc: nowUtc,
        ),
        throwsArgumentError,
      );
    });

    test('implements value equality', () {
      final a = WorkoutSessionSnapshot(
        routineId: RoutineId(routineUuid),
        routineName: 'Chest Day',
        programId: ProgramId(programUuid),
        capturedAtUtc: nowUtc,
      );
      final b = WorkoutSessionSnapshot(
        routineId: RoutineId(routineUuid),
        routineName: 'Chest Day',
        programId: ProgramId(programUuid),
        capturedAtUtc: nowUtc,
      );
      final c = WorkoutSessionSnapshot(
        routineId: RoutineId(routineUuid),
        routineName: 'Leg Day',
        programId: ProgramId(programUuid),
        capturedAtUtc: nowUtc,
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });
}

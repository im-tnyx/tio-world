import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const userUuid = '01920f3e-7c4a-7b2d-9e1f-2a3b4c5d6e7f';
  const programUuid = 'c232ab00-9414-11ec-b3c8-9f6bdeced846';
  const routineUuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';
  final exBench = ExerciseRef.catalog('ex_barbell_bench_press');
  final exRun = ExerciseRef.catalog('ex_running');

  final benchExercise = Exercise(
    ref: exBench,
    displayName: 'Barbell Bench Press',
    exerciseType: ExerciseType.weightReps,
    status: ExerciseStatus.active,
  );

  final runExercise = Exercise(
    ref: exRun,
    displayName: 'Running',
    exerciseType: ExerciseType.distanceDuration,
    status: ExerciseStatus.active,
  );

  final program = Program(
    id: ProgramId(programUuid),
    name: 'Strength Program',
  );

  final routine = Routine(
    id: RoutineId(routineUuid),
    programId: ProgramId(programUuid),
    name: 'Chest Day',
  );

  group('WorkoutReadinessValidator', () {
    test('succeeds for valid Routine with Weight & Reps exercises', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          RoutineExercise(
            exercise: exBench,
            sets: [
              SetPrescription(
                reps: 10,
                loadKg: 60,
                setType: RoutineSetType.warmUp,
              ),
              SetPrescription(
                reps: 8,
                loadKg: 80,
                setType: RoutineSetType.normal,
              ),
            ],
          ),
        ],
      );

      final result = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {exBench: benchExercise},
        evaluationTimeUtc: DateTime.utc(2026, 11, 5, 12, 0, 0),
      );

      expect(result.isReady, isTrue);
      expect(result, isA<WorkoutExecutionReady>());
      final ready = result as WorkoutExecutionReady;
      expect(ready.snapshot.routineId, RoutineId(routineUuid));
      expect(ready.snapshot.routineName, 'Chest Day');
      expect(ready.snapshot.programId, ProgramId(programUuid));
      expect(ready.snapshot.exercises, hasLength(1));
      expect(ready.snapshot.exercises[0].exerciseRef, exBench);
      expect(ready.snapshot.exercises[0].displayName, 'Barbell Bench Press');
      expect(ready.snapshot.exercises[0].prescribedSets, hasLength(2));
    });

    test('accepts custom exercise with untyped (null) measurement profile', () {
      final customRef =
          ExerciseRef.userCreated('d89b3f4a-7c2d-4e5f-9a1b-3c4d5e6f7a8b');
      final customExercise = Exercise(
        ref: customRef,
        displayName: 'My Custom Press',
        exerciseType: null, // Untyped custom defaults to reps/load
        status: ExerciseStatus.active,
      );

      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          RoutineExercise(
            exercise: customRef,
            sets: [SetPrescription(reps: 12, loadKg: 20)],
          ),
        ],
      );

      final result = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {customRef: customExercise},
      );

      expect(result.isReady, isTrue);
    });

    test('fails when Routine does not belong to the Program', () {
      final foreignRoutine = Routine(
        id: RoutineId(routineUuid),
        programId: ProgramId('00000000-0000-4000-8000-000000000001'),
        name: 'Foreign Routine',
      );

      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          RoutineExercise(
            exercise: exBench,
            sets: [SetPrescription(reps: 10)],
          ),
        ],
      );

      final result = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: foreignRoutine,
        composition: composition,
        resolvedExercises: {exBench: benchExercise},
      );

      expect(result.isReady, isFalse);
      final rejected = result as WorkoutExecutionRejected;
      expect(
        rejected.reason,
        WorkoutReadinessRejectionReason.invalidOwnershipContext,
      );
    });

    test('fails for empty Routine (zero exercises)', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: const [],
      );

      final result = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {},
      );

      expect(result.isReady, isFalse);
      final rejected = result as WorkoutExecutionRejected;
      expect(rejected.reason, WorkoutReadinessRejectionReason.emptyRoutine);
    });

    test('fails when Routine has exercises but zero total sets', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          RoutineExercise(
            exercise: exBench,
            sets: const [],
          ),
        ],
      );

      final result = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {exBench: benchExercise},
      );

      expect(result.isReady, isFalse);
      final rejected = result as WorkoutExecutionRejected;
      expect(rejected.reason, WorkoutReadinessRejectionReason.noExecutableSets);
    });

    test('fails when an exercise is unresolvable or archived', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          RoutineExercise(
            exercise: exBench,
            sets: [SetPrescription(reps: 10)],
          ),
        ],
      );

      // Missing
      final missingResult = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {},
      );
      expect(missingResult.isReady, isFalse);
      expect(
        (missingResult as WorkoutExecutionRejected).reason,
        WorkoutReadinessRejectionReason.missingExercise,
      );

      // Archived
      final archivedBench = Exercise(
        ref: exBench,
        displayName: 'Old Bench',
        status: ExerciseStatus.archived,
      );
      final archivedResult = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {exBench: archivedBench},
      );
      expect(archivedResult.isReady, isFalse);
      expect(
        (archivedResult as WorkoutExecutionRejected).reason,
        WorkoutReadinessRejectionReason.missingExercise,
      );
    });

    test('fails when exercise uses an unsupported measurement profile in W7A', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          RoutineExercise(
            exercise: exRun,
            sets: [SetPrescription(distanceMeters: 5000, durationSeconds: 1500)],
          ),
        ],
      );

      final result = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {exRun: runExercise},
      );

      expect(result.isReady, isFalse);
      final rejected = result as WorkoutExecutionRejected;
      expect(
        rejected.reason,
        WorkoutReadinessRejectionReason.unsupportedMeasurementProfile,
      );
      expect(rejected.exerciseRef, exRun);
      expect(rejected.entryIndex, 0);
    });

    test('fails when set composition violates warm-up ordering', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          RoutineExercise(
            exercise: exBench,
            sets: [
              SetPrescription(reps: 10, setType: RoutineSetType.normal),
              SetPrescription(reps: 10, setType: RoutineSetType.warmUp), // Warm-up after normal!
            ],
          ),
        ],
      );

      final result = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {exBench: benchExercise},
      );

      expect(result.isReady, isFalse);
      final rejected = result as WorkoutExecutionRejected;
      expect(
        rejected.reason,
        WorkoutReadinessRejectionReason.invalidRoutineComposition,
      );
    });

    test('fails when sets exceed maximum limit of 8 per exercise', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          RoutineExercise(
            exercise: exBench,
            sets: List.generate(9, (i) => SetPrescription(reps: 10)),
          ),
        ],
      );

      final result = WorkoutReadinessValidator.evaluate(
        userId: userUuid,
        program: program,
        routine: routine,
        composition: composition,
        resolvedExercises: {exBench: benchExercise},
      );

      expect(result.isReady, isFalse);
      final rejected = result as WorkoutExecutionRejected;
      expect(
        rejected.reason,
        WorkoutReadinessRejectionReason.invalidRoutineComposition,
      );
    });
  });
}

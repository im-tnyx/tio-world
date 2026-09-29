import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const routineUuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';

  RoutineExercise entry(
    String exerciseId, {
    List<SetPrescription> sets = const [],
  }) =>
      RoutineExercise(
        exercise: ExerciseRef.catalog(exerciseId),
        sets: sets,
      );

  group('RoutineExercise', () {
    test('preserves prescribed set order and defensively copies input', () {
      final source = [
        SetPrescription(reps: 10, loadKg: 40),
        SetPrescription(reps: 8, loadKg: 45),
      ];

      final exercise = entry(
        'ex_barbell_bench_press',
        sets: source,
      );
      source.clear();

      expect(exercise.sets, hasLength(2));
      expect(exercise.sets[0].reps, 10);
      expect(exercise.sets[1].reps, 8);
      expect(
        () => exercise.sets.add(SetPrescription(reps: 6)),
        throwsUnsupportedError,
      );
    });

    test('allows an empty set list for an incomplete composition', () {
      final exercise = entry('ex_barbell_bench_press');

      expect(exercise.sets, isEmpty);
    });

    test('uses value equality', () {
      final a = entry(
        'ex_barbell_bench_press',
        sets: [SetPrescription(reps: 8, loadKg: 60)],
      );
      final b = entry(
        'ex_barbell_bench_press',
        sets: [SetPrescription(reps: 8, loadKg: 60)],
      );
      final changed = entry(
        'ex_barbell_bench_press',
        sets: [SetPrescription(reps: 10, loadKg: 60)],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(changed));
    });
  });

  group('RoutineComposition', () {
    test('preserves Exercise order and defensively copies input', () {
      final source = [
        entry('ex_barbell_bench_press'),
        entry('ex_barbell_back_squat'),
      ];

      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: source,
      );
      source.clear();

      expect(composition.exercises, hasLength(2));
      expect(
        composition.exercises[0].exercise,
        ExerciseRef.catalog('ex_barbell_bench_press'),
      );
      expect(
        composition.exercises[1].exercise,
        ExerciseRef.catalog('ex_barbell_back_squat'),
      );
      expect(
        () => composition.exercises.add(entry('ex_deadlift')),
        throwsUnsupportedError,
      );
    });

    test('allows repeated Exercise references without deduplicating', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [
          entry('ex_barbell_bench_press'),
          entry('ex_barbell_back_squat'),
          entry('ex_barbell_bench_press'),
        ],
      );

      expect(composition.exercises, hasLength(3));
      expect(
        composition.exercises.first.exercise,
        composition.exercises.last.exercise,
      );
    });

    test('allows an empty composition', () {
      final composition = RoutineComposition(
        routineId: RoutineId(routineUuid),
      );

      expect(composition.exercises, isEmpty);
    });

    test('equality includes Routine identity and ordered entries', () {
      final ordered = [
        entry('ex_barbell_bench_press'),
        entry('ex_barbell_back_squat'),
      ];
      final a = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: ordered,
      );
      final b = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: [...ordered],
      );
      final reversed = RoutineComposition(
        routineId: RoutineId(routineUuid),
        exercises: ordered.reversed.toList(),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(reversed));
    });
  });
}

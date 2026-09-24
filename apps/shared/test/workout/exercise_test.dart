import 'package:test/test.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const userCreatedUuid = '3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c';

  Exercise createExercise({
    ExerciseRef? ref,
    String displayName = 'Bench Press',
    String? muscleGroup = 'chest',
    List<String> primaryMuscles = const ['pectoralis_major'],
    List<String> secondaryMuscles = const ['triceps', 'anterior_deltoid'],
    String? primaryEquipment = 'barbell',
    String? category = 'strength',
    List<String> levels = const ['beginner', 'intermediate'],
    ExerciseStatus status = ExerciseStatus.active,
  }) =>
      Exercise(
        ref: ref ?? ExerciseRef.catalog('ex_barbell_bench_press'),
        displayName: displayName,
        muscleGroup: muscleGroup,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        primaryEquipment: primaryEquipment,
        category: category,
        levels: levels,
        status: status,
      );

  group('identity variants', () {
    test('constructs a catalog Exercise from a catalog ref', () {
      final exercise = createExercise();

      expect(exercise, isA<Exercise>());
      expect(exercise.ref, isA<CatalogExerciseRef>());
      expect(exercise.ref.value, 'ex_barbell_bench_press');
    });

    test('constructs the same Exercise type from a user-created ref', () {
      final exercise = createExercise(
        ref: ExerciseRef.userCreated(userCreatedUuid),
      );

      expect(exercise, isA<Exercise>());
      expect(exercise.ref, isA<UserCreatedExerciseRef>());
      expect(exercise.ref.value, userCreatedUuid);
    });

    test('does not require a catalog lookup for an unknown future ref', () {
      final exercise = createExercise(
        ref: ExerciseRef.catalog('ex_future_movement'),
      );

      expect(exercise.ref.value, 'ex_future_movement');
    });
  });

  group('displayName', () {
    test('rejects blank and whitespace-only values', () {
      for (final value in ['', '   ', '\n\t']) {
        expect(
          () => createExercise(displayName: value),
          throwsArgumentError,
          reason: value,
        );
      }
    });

    test('preserves supplied nonblank text', () {
      expect(createExercise(displayName: ' Bench Press ').displayName,
          ' Bench Press ');
    });
  });

  group('taxonomy', () {
    test('allows nullable scalar and empty collection taxonomy', () {
      final exercise = createExercise(
        muscleGroup: null,
        primaryMuscles: const [],
        secondaryMuscles: const [],
        primaryEquipment: null,
        category: null,
        levels: const [],
      );

      expect(exercise.muscleGroup, isNull);
      expect(exercise.primaryMuscles, isEmpty);
      expect(exercise.secondaryMuscles, isEmpty);
      expect(exercise.primaryEquipment, isNull);
      expect(exercise.category, isNull);
      expect(exercise.levels, isEmpty);
    });

    test('accepts unknown future taxonomy strings', () {
      final exercise = createExercise(
        muscleGroup: 'future_group',
        primaryMuscles: const ['future_primary'],
        secondaryMuscles: const ['future_secondary'],
        primaryEquipment: 'future_equipment',
        category: 'future_category',
        levels: const ['future_level'],
      );

      expect(exercise.muscleGroup, 'future_group');
      expect(exercise.primaryMuscles, ['future_primary']);
      expect(exercise.secondaryMuscles, ['future_secondary']);
      expect(exercise.primaryEquipment, 'future_equipment');
      expect(exercise.category, 'future_category');
      expect(exercise.levels, ['future_level']);
    });

    test('rejects empty and whitespace-only scalar taxonomy values', () {
      for (final value in ['', ' ', '\t', '\n']) {
        expect(() => createExercise(muscleGroup: value), throwsArgumentError,
            reason: value);
        expect(
            () => createExercise(primaryEquipment: value), throwsArgumentError,
            reason: value);
        expect(() => createExercise(category: value), throwsArgumentError,
            reason: value);
      }
    });

    test('rejects empty and whitespace-only collection taxonomy values', () {
      for (final value in ['', ' ', '\t', '\n']) {
        expect(
            () => createExercise(primaryMuscles: [value]), throwsArgumentError,
            reason: value);
        expect(() => createExercise(secondaryMuscles: [value]),
            throwsArgumentError,
            reason: value);
        expect(() => createExercise(levels: ['beginner', value]),
            throwsArgumentError,
            reason: value);
      }
    });

    test('rejects duplicate collection taxonomy values', () {
      expect(
        () => createExercise(
          primaryMuscles: const ['chest', 'chest'],
        ),
        throwsArgumentError,
      );
      expect(
        () => createExercise(
          secondaryMuscles: const ['triceps', 'triceps'],
        ),
        throwsArgumentError,
      );
      expect(
        () => createExercise(levels: const ['beginner', 'beginner']),
        throwsArgumentError,
      );
    });

    test('defensively copies input collections', () {
      final primary = <String>['pectoralis_major'];
      final secondary = <String>['triceps'];
      final levels = <String>['beginner'];
      final exercise = createExercise(
        primaryMuscles: primary,
        secondaryMuscles: secondary,
        levels: levels,
      );

      primary.add('future_primary');
      secondary.add('future_secondary');
      levels.add('future_level');

      expect(exercise.primaryMuscles, ['pectoralis_major']);
      expect(exercise.secondaryMuscles, ['triceps']);
      expect(exercise.levels, ['beginner']);
    });

    test('exposes unmodifiable collections', () {
      final exercise = createExercise();

      expect(
        () => exercise.primaryMuscles.add('future_primary'),
        throwsUnsupportedError,
      );
      expect(
        () => exercise.secondaryMuscles.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => exercise.levels[0] = 'future_level',
        throwsUnsupportedError,
      );
    });

    test('preserves collection ordering', () {
      final exercise = createExercise(
        primaryMuscles: const ['first', 'second'],
        secondaryMuscles: const ['third', 'fourth'],
        levels: const ['beginner', 'advanced'],
      );

      expect(exercise.primaryMuscles, ['first', 'second']);
      expect(exercise.secondaryMuscles, ['third', 'fourth']);
      expect(exercise.levels, ['beginner', 'advanced']);
    });
  });

  group('value semantics', () {
    test('equal values have equal hashes with different list instances', () {
      final a = createExercise(
        primaryMuscles: <String>['pectoralis_major'],
        secondaryMuscles: <String>['triceps', 'anterior_deltoid'],
        levels: <String>['beginner', 'intermediate'],
      );
      final b = createExercise(
        primaryMuscles: <String>['pectoralis_major'],
        secondaryMuscles: <String>['triceps', 'anterior_deltoid'],
        levels: <String>['beginner', 'intermediate'],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect({a, b}, hasLength(1));
    });

    test('different refs are unequal', () {
      expect(
        createExercise(),
        isNot(
          createExercise(ref: ExerciseRef.catalog('ex_barbell_row')),
        ),
      );
    });

    test('every canonical metadata field participates in equality', () {
      final baseline = createExercise();
      final variants = <Exercise>[
        createExercise(displayName: 'Incline Bench Press'),
        createExercise(muscleGroup: 'upper_body'),
        createExercise(primaryMuscles: const ['upper_pectoralis']),
        createExercise(secondaryMuscles: const ['triceps']),
        createExercise(primaryEquipment: 'dumbbell'),
        createExercise(category: 'power'),
        createExercise(levels: const ['advanced']),
        createExercise(muscleGroup: null),
        createExercise(primaryEquipment: null),
        createExercise(category: null),
        createExercise(primaryMuscles: const []),
        createExercise(secondaryMuscles: const []),
        createExercise(levels: const []),
      ];

      for (final variant in variants) {
        expect(baseline, isNot(variant));
      }
    });

    test('collection ordering participates in equality', () {
      expect(
        createExercise(primaryMuscles: const ['first', 'second']),
        isNot(
          createExercise(primaryMuscles: const ['second', 'first']),
        ),
      );
    });

    test('active and archived statuses are unequal', () {
      final active = createExercise(status: ExerciseStatus.active);
      final archived = createExercise(status: ExerciseStatus.archived);

      expect(active.status, ExerciseStatus.active);
      expect(archived.status, ExerciseStatus.archived);
      expect(active, isNot(archived));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('UserExerciseDefinition', () {
    test('normalizes blank description to null', () {
      expect(UserExerciseDefinition(description: '   ').description, isNull);
      expect(
        UserExerciseDefinition(description: ' Tempo ').description,
        'Tempo',
      );
    });

    test('accepts approved taxonomy and exposes immutable secondary muscles', () {
      final definition = UserExerciseDefinition(
        exerciseType: ExerciseType.dumbbellX2Simultaneous,
        primaryMuscle: 'pectoralis_major_sternal_head',
        secondaryMuscles: const ['triceps_brachii'],
        primaryEquipment: 'dumbbell',
      );

      expect(definition.exerciseType?.storageValue, 'dumbbell_x2_simultaneous');
      expect(definition.secondaryMuscles, ['triceps_brachii']);
      expect(
        () => definition.secondaryMuscles.add('deltoid_anterior'),
        throwsUnsupportedError,
      );
    });

    test('rejects unknown, duplicate and primary-as-secondary muscle tokens', () {
      expect(
        () => UserExerciseDefinition(primaryMuscle: 'unknown'),
        throwsArgumentError,
      );
      expect(
        () => UserExerciseDefinition(
          secondaryMuscles: const ['triceps_brachii', 'triceps_brachii'],
        ),
        throwsArgumentError,
      );
      expect(
        () => UserExerciseDefinition(
          primaryMuscle: 'triceps_brachii',
          secondaryMuscles: const ['triceps_brachii'],
        ),
        throwsArgumentError,
      );
    });

    test('rejects unknown equipment token', () {
      expect(
        () => UserExerciseDefinition(primaryEquipment: 'unknown'),
        throwsArgumentError,
      );
    });
  });

  group('ExerciseType', () {
    test('round-trips all 11 stable storage values', () {
      expect(ExerciseType.values, hasLength(11));
      for (final type in ExerciseType.values) {
        expect(ExerciseType.fromStorageValue(type.storageValue), type);
      }
    });

    test('rejects unknown storage values', () {
      expect(
        () => ExerciseType.fromStorageValue('unknown'),
        throwsFormatException,
      );
    });
  });
}

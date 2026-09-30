import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('migration taxonomy matches the canonical Dart storage contracts', () {
    final migration = File(
      '../../../supabase/migrations/'
      '20260930180700_add_custom_exercise_definition_fields.sql',
    ).readAsStringSync();
    Set<String> sqlTokens(String marker) {
      final section = migration.substring(migration.indexOf(marker));
      final array = RegExp(r'array\[([\s\S]*?)\]::text\[\]')
          .firstMatch(section)!
          .group(1)!;
      return RegExp("'([^']+)'")
          .allMatches(array)
          .map((match) => match.group(1)!)
          .toSet();
    }

    expect(sqlTokens('-- W3D2 muscle tokens'),
        UserExerciseDefinition.muscleTokens);
    expect(sqlTokens('-- W3D2 equipment tokens'),
        UserExerciseDefinition.equipmentTokens);
    expect(sqlTokens('-- W3D2 type tokens'),
        ExerciseType.values.map((type) => type.storageValue).toSet());
  });

  group('UserExerciseDefinition', () {
    test('normalizes blank description to null', () {
      expect(UserExerciseDefinition(description: '   ').description, isNull);
      expect(
        UserExerciseDefinition(description: ' Tempo ').description,
        'Tempo',
      );
    });

    test('accepts approved taxonomy and exposes immutable secondary muscles',
        () {
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

    test('rejects unknown, duplicate and primary-as-secondary muscle tokens',
        () {
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

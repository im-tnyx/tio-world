import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/src/domain/exercises/user_exercise_definition.dart';
import 'package:tio_feature_workout/src/presentation/library/exercises/custom_exercise_editor_options.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('Primary Body Part groups cover every canonical muscle exactly once', () {
    final grouped = customExercisePrimaryBodyParts
        .expand((group) => group.muscles)
        .toList(growable: false);

    expect(grouped.toSet(), UserExerciseDefinition.muscleTokens);
    expect(grouped.length, grouped.toSet().length);
  });

  test('Exercise Type options cover the canonical enum exactly once', () {
    final types = customExerciseTypeOptions
        .map((option) => option.type)
        .toList(growable: false);

    expect(types.toSet(), ExerciseType.values.toSet());
    expect(types.length, ExerciseType.values.length);
    expect(types.length, types.toSet().length);
    expect(
      customExerciseTypeOptionFor(ExerciseType.fullBodyweight).hints,
      ['+KG', 'REPS'],
    );
  });
}

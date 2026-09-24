import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

// Synthetic fixtures only.
Exercise syntheticExercise(
  String id,
  String displayName, {
  ExerciseStatus status = ExerciseStatus.active,
}) =>
    Exercise(
      ref: ExerciseRef.catalog(id),
      displayName: displayName,
      status: status,
    );

void main() {
  test('all holds every Exercise in name then id order', () {
    final catalog = ExerciseCatalog([
      syntheticExercise('ex_synthetic_c', 'charlie lift'),
      syntheticExercise('ex_synthetic_b2', 'Bravo Lift'),
      syntheticExercise('ex_synthetic_a', 'Alpha Lift'),
      syntheticExercise('ex_synthetic_b1', 'bravo lift'),
    ]);

    expect(catalog.all.map((exercise) => exercise.ref.value), [
      'ex_synthetic_a',
      'ex_synthetic_b1',
      'ex_synthetic_b2',
      'ex_synthetic_c',
    ]);
  });

  test('order does not depend on input order', () {
    final exercises = [
      syntheticExercise('ex_synthetic_b', 'Bravo'),
      syntheticExercise('ex_synthetic_a', 'Alpha'),
    ];

    expect(
      ExerciseCatalog(exercises).all,
      ExerciseCatalog(exercises.reversed).all,
    );
  });

  test('byRef finds an Exercise and returns null for an unknown ref', () {
    final alpha = syntheticExercise('ex_synthetic_a', 'Alpha');
    final catalog = ExerciseCatalog([alpha]);

    expect(catalog.byRef(ExerciseRef.catalog('ex_synthetic_a')), alpha);
    expect(catalog.byRef(ExerciseRef.catalog('ex_synthetic_z')), isNull);
  });

  test('archived exercises stay in the catalog', () {
    final archived = syntheticExercise(
      'ex_synthetic_old',
      'Old Lift',
      status: ExerciseStatus.archived,
    );
    final catalog = ExerciseCatalog([archived]);

    expect(catalog.all, [archived]);
    expect(catalog.byRef(archived.ref), archived);
  });

  test('rejects duplicate ExerciseRefs', () {
    expect(
      () => ExerciseCatalog([
        syntheticExercise('ex_synthetic_a', 'Alpha'),
        syntheticExercise('ex_synthetic_a', 'Alpha Again'),
      ]),
      throwsArgumentError,
    );
  });

  test('rejects user-created exercises', () {
    expect(
      () => ExerciseCatalog([
        Exercise(
          ref: ExerciseRef.userCreated('3f2c8e4a-9b1d-4c7e-8a5f-1d2e3f4a5b6c'),
          displayName: 'Synthetic Custom Lift',
          status: ExerciseStatus.active,
        ),
      ]),
      throwsArgumentError,
    );
  });

  test('exposes an unmodifiable list', () {
    final catalog = ExerciseCatalog([syntheticExercise('ex_synthetic_a', 'A')]);

    expect(() => catalog.all.clear(), throwsUnsupportedError);
    expect(ExerciseCatalog(const []).isEmpty, isTrue);
  });
}

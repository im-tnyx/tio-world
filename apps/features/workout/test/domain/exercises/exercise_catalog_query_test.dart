import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

// Synthetic fixtures only.
Exercise syntheticExercise(
  String id,
  String displayName, {
  String? muscleGroup,
  String? primaryEquipment,
  String? category,
  ExerciseStatus status = ExerciseStatus.active,
}) =>
    Exercise(
      ref: ExerciseRef.catalog(id),
      displayName: displayName,
      muscleGroup: muscleGroup,
      primaryEquipment: primaryEquipment,
      category: category,
      status: status,
    );

List<String> refsOf(List<Exercise> exercises) =>
    [for (final exercise in exercises) exercise.ref.value];

void main() {
  final catalog = ExerciseCatalog([
    syntheticExercise(
      'ex_synthetic_press',
      'Synthetic  Overhead Press',
      muscleGroup: 'group_upper',
      primaryEquipment: 'gear_a',
      category: 'kind_a',
    ),
    syntheticExercise(
      'ex_synthetic_row',
      'Synthetic Row',
      muscleGroup: 'group_upper',
      primaryEquipment: 'gear_b',
      category: 'kind_a',
    ),
    syntheticExercise(
      'ex_synthetic_squat',
      'Synthetic Squat',
      muscleGroup: 'group_lower',
      primaryEquipment: 'gear_a',
      category: 'kind_b',
    ),
    syntheticExercise(
      'ex_synthetic_archived',
      'Synthetic Archived Press',
      muscleGroup: 'group_upper',
      primaryEquipment: 'gear_a',
      category: 'kind_a',
      status: ExerciseStatus.archived,
    ),
  ]);

  group('search', () {
    test('empty text returns every active Exercise in display order', () {
      expect(refsOf(const ExerciseCatalogQuery().apply(catalog)), [
        'ex_synthetic_press',
        'ex_synthetic_row',
        'ex_synthetic_squat',
      ]);
      expect(
        refsOf(const ExerciseCatalogQuery(text: '   ').apply(catalog)),
        hasLength(3),
      );
    });

    test('matches case-insensitively', () {
      expect(
        refsOf(const ExerciseCatalogQuery(text: 'SQUAT').apply(catalog)),
        ['ex_synthetic_squat'],
      );
    });

    test('matches a substring anywhere in the display name', () {
      expect(
        refsOf(const ExerciseCatalogQuery(text: 'rhead pr').apply(catalog)),
        ['ex_synthetic_press'],
      );
    });

    test('trims and collapses whitespace on both sides', () {
      expect(
        refsOf(
          const ExerciseCatalogQuery(text: '  overhead \t  press ')
              .apply(catalog),
        ),
        ['ex_synthetic_press'],
      );
    });

    test('returns an empty list for no match', () {
      expect(
        const ExerciseCatalogQuery(text: 'no such lift').apply(catalog),
        isEmpty,
      );
    });

    test('hides archived exercises even when they match', () {
      expect(
        refsOf(const ExerciseCatalogQuery(text: 'archived').apply(catalog)),
        isEmpty,
      );
      expect(catalog.all, hasLength(4));
    });
  });

  group('filters', () {
    test('muscleGroup', () {
      expect(
        refsOf(
          const ExerciseCatalogQuery(muscleGroup: 'group_upper').apply(catalog),
        ),
        ['ex_synthetic_press', 'ex_synthetic_row'],
      );
    });

    test('primaryEquipment', () {
      expect(
        refsOf(
          const ExerciseCatalogQuery(primaryEquipment: 'gear_a').apply(catalog),
        ),
        ['ex_synthetic_press', 'ex_synthetic_squat'],
      );
    });

    test('category', () {
      expect(
        refsOf(const ExerciseCatalogQuery(category: 'kind_b').apply(catalog)),
        ['ex_synthetic_squat'],
      );
    });

    test('filter values match exactly', () {
      expect(
        const ExerciseCatalogQuery(muscleGroup: 'GROUP_UPPER').apply(catalog),
        isEmpty,
      );
    });

    test('search and filters compose', () {
      expect(
        refsOf(
          const ExerciseCatalogQuery(
            text: 'synthetic',
            muscleGroup: 'group_upper',
            primaryEquipment: 'gear_a',
            category: 'kind_a',
          ).apply(catalog),
        ),
        ['ex_synthetic_press'],
      );
    });
  });

  test('orders equal names by ExerciseRef value', () {
    final tied = ExerciseCatalog([
      syntheticExercise('ex_synthetic_b', 'Same Name'),
      syntheticExercise('ex_synthetic_a', 'same name'),
    ]);

    expect(
      refsOf(const ExerciseCatalogQuery().apply(tied)),
      ['ex_synthetic_a', 'ex_synthetic_b'],
    );
  });

  test('queries with equal values are equal', () {
    expect(
      const ExerciseCatalogQuery(text: 'a', category: 'kind_a'),
      const ExerciseCatalogQuery(text: 'a', category: 'kind_a'),
    );
    expect(
      const ExerciseCatalogQuery(text: 'a').hashCode,
      const ExerciseCatalogQuery(text: 'a').hashCode,
    );
    expect(
      const ExerciseCatalogQuery(text: 'a'),
      isNot(const ExerciseCatalogQuery(text: 'b')),
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

// Synthetic fixtures only. Never copy rows, names or IDs from the owner
// Exercise catalog into these tests.
Map<String, Object?> syntheticRow({
  String id = 'ex_synthetic_alpha',
  String title = 'Synthetic Alpha Lift',
}) =>
    {
      'id': id,
      'title': title,
      'muscleGroup': 'group_upper',
      'primaryMuscles': ['muscle_a', 'muscle_b'],
      'secondaryMuscles': ['muscle_c'],
      'equipment': {
        'primary': 'gear_a',
        'items': ['gear_a_variant'],
      },
      'category': 'kind_a',
      'levels': ['level_1', 'level_2'],
      'isArchived': false,
      'isCustom': false,
    };

Map<String, Object?> withField(String key, Object? value) =>
    syntheticRow()..[key] = value;

Map<String, Object?> withoutField(String key) => syntheticRow()..remove(key);

InvalidExerciseCatalogException parseFailure(List<Object?> rows) {
  try {
    const ExerciseCatalogParser().parse(rows);
  } on InvalidExerciseCatalogException catch (error) {
    return error;
  }
  fail('Expected InvalidExerciseCatalogException');
}

void expectSingleIssue(Object? row, String path) {
  final issues = parseFailure([row]).issues;
  expect(issues, hasLength(1), reason: issues.join('; '));
  expect(issues.single.rowIndex, 0);
  expect(issues.single.path, path);
}

void main() {
  const parser = ExerciseCatalogParser();

  group('valid rows', () {
    test('map every consumed field into canonical Exercise', () {
      final exercise = parser.parse([syntheticRow()]).all.single;

      expect(exercise.ref, isA<CatalogExerciseRef>());
      expect(exercise.ref, ExerciseRef.catalog('ex_synthetic_alpha'));
      expect(exercise.displayName, 'Synthetic Alpha Lift');
      expect(exercise.muscleGroup, 'group_upper');
      expect(exercise.primaryMuscles, ['muscle_a', 'muscle_b']);
      expect(exercise.secondaryMuscles, ['muscle_c']);
      expect(exercise.primaryEquipment, 'gear_a');
      expect(exercise.category, 'kind_a');
      expect(exercise.levels, ['level_1', 'level_2']);
      expect(exercise.status, ExerciseStatus.active);
    });

    test('map isArchived true to archived status', () {
      final exercise = parser.parse([withField('isArchived', true)]).all.single;

      expect(exercise.status, ExerciseStatus.archived);
    });

    test('accept empty secondaryMuscles', () {
      final exercise =
          parser.parse([withField('secondaryMuscles', <Object?>[])]).all.single;

      expect(exercise.secondaryMuscles, isEmpty);
    });

    test('ignore unknown and deferred keys', () {
      final row = syntheticRow()
        ..['slug'] = 'synthetic-alpha'
        ..['media'] = {'type': 'none'}
        ..['futureField'] = 42;

      expect(
          parser.parse([row]).all.single.displayName, 'Synthetic Alpha Lift');
    });

    test('accept an empty row list as an empty catalog', () {
      expect(parser.parse(const []).isEmpty, isTrue);
    });
  });

  group('invalid rows', () {
    test('reject each missing consumed field', () {
      for (final key in [
        'id',
        'title',
        'muscleGroup',
        'primaryMuscles',
        'secondaryMuscles',
        'equipment',
        'category',
        'levels',
        'isArchived',
        'isCustom',
      ]) {
        final issues = parseFailure([withoutField(key)]).issues;
        expect(issues.single.path, key, reason: key);
        expect(issues.single.problem, 'is required', reason: key);
      }
    });

    test('reject a missing equipment.primary', () {
      expectSingleIssue(
        withField('equipment', {'items': <Object?>[]}),
        'equipment.primary',
      );
    });

    test('reject wrong scalar types', () {
      expectSingleIssue(withField('id', 7), 'id');
      expectSingleIssue(withField('title', null), 'title');
      expectSingleIssue(
          withField('muscleGroup', ['group_upper']), 'muscleGroup');
      expectSingleIssue(withField('category', false), 'category');
      expectSingleIssue(withField('isArchived', 'false'), 'isArchived');
      expectSingleIssue(withField('isCustom', 0), 'isCustom');
    });

    test('reject wrong list types', () {
      expectSingleIssue(
          withField('primaryMuscles', 'muscle_a'), 'primaryMuscles');
      expectSingleIssue(
        withField('secondaryMuscles', ['muscle_c', 3]),
        'secondaryMuscles',
      );
      expectSingleIssue(withField('levels', null), 'levels');
    });

    test('reject a malformed equipment object', () {
      expectSingleIssue(withField('equipment', 'gear_a'), 'equipment');
      expectSingleIssue(
        withField('equipment', {'primary': 5}),
        'equipment.primary',
      );
    });

    test('reject blank title and blank scalar taxonomy', () {
      expectSingleIssue(withField('title', '  '), 'title');
      expectSingleIssue(withField('muscleGroup', ''), 'muscleGroup');
      expectSingleIssue(withField('category', '\t'), 'category');
      expectSingleIssue(
        withField('equipment', {'primary': ' '}),
        'equipment.primary',
      );
    });

    test('reject blank and duplicate taxonomy tokens', () {
      expectSingleIssue(withField('primaryMuscles', ['']), 'primaryMuscles');
      expectSingleIssue(
        withField('secondaryMuscles', ['muscle_c', ' ']),
        'secondaryMuscles',
      );
      expectSingleIssue(
        withField('levels', ['level_1', 'level_1']),
        'levels',
      );
    });

    test('reject a malformed catalog id', () {
      for (final id in ['', 'synthetic_alpha', 'ex_', 'EX_ALPHA', 'ex-alpha']) {
        expectSingleIssue(withField('id', id), 'id');
      }
    });

    test('reject a user-created row in the bundled catalog', () {
      final issue = parseFailure([withField('isCustom', true)]).issues.single;

      expect(issue.path, 'isCustom');
      expect(issue.exerciseId, 'ex_synthetic_alpha');
    });

    test('reject a row that is not an object', () {
      expectSingleIssue('ex_synthetic_alpha', r'$');
    });
  });

  group('whole-catalog policy', () {
    test('all valid rows succeed', () {
      final catalog = parser.parse([
        syntheticRow(),
        syntheticRow(id: 'ex_synthetic_beta', title: 'Synthetic Beta Lift'),
      ]);

      expect(catalog.all, hasLength(2));
    });

    test('one invalid row fails the entire catalog', () {
      expect(
        () => parser.parse([
          syntheticRow(),
          withField('title', ''),
          syntheticRow(id: 'ex_synthetic_gamma', title: 'Synthetic Gamma'),
        ]),
        throwsA(isA<InvalidExerciseCatalogException>()),
      );
    });

    test('collect diagnostics across rows with row index, id and path', () {
      final issues = parseFailure([
        syntheticRow(),
        syntheticRow(id: 'ex_synthetic_beta')..remove('category'),
        syntheticRow(id: 'ex_synthetic_gamma')
          ..['levels'] = 'level_1'
          ..['isCustom'] = true,
      ]).issues;

      expect(issues, [
        const ExerciseCatalogIssue(
          rowIndex: 1,
          exerciseId: 'ex_synthetic_beta',
          path: 'category',
          problem: 'is required',
        ),
        const ExerciseCatalogIssue(
          rowIndex: 2,
          exerciseId: 'ex_synthetic_gamma',
          path: 'levels',
          problem: 'must be a list',
        ),
        const ExerciseCatalogIssue(
          rowIndex: 2,
          exerciseId: 'ex_synthetic_gamma',
          path: 'isCustom',
          problem: 'must be false for a built-in catalog row',
        ),
      ]);
    });

    test('duplicate catalog ExerciseRefs fail instead of overwriting', () {
      final issue = parseFailure([
        syntheticRow(),
        syntheticRow(title: 'Synthetic Alpha Copy'),
      ]).issues.single;

      expect(issue.rowIndex, 1);
      expect(issue.exerciseId, 'ex_synthetic_alpha');
      expect(issue.path, 'id');
      expect(issue.problem, contains('row 0'));
    });
  });

  group('DecodedRowsExerciseCatalogRepository', () {
    test('loads and validates supplied rows', () async {
      final repository = DecodedRowsExerciseCatalogRepository(
        () async => [syntheticRow()],
      );

      final catalog = await repository.load();

      expect(
          catalog.byRef(ExerciseRef.catalog('ex_synthetic_alpha')), isNotNull);
    });

    test('surfaces invalid rows as InvalidExerciseCatalogException', () {
      final repository = DecodedRowsExerciseCatalogRepository(
        () async => [withoutField('title')],
      );

      expect(
        repository.load(),
        throwsA(isA<InvalidExerciseCatalogException>()),
      );
    });
  });
}

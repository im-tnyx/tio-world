import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';
import 'package:tio_shared/shared.dart';

import 'exercises_fixtures.dart';

List<String> refsOf(ExercisesState state) =>
    [for (final item in state.items) item.exercise.ref.value];

Future<ExercisesController> loadedController({
  ExerciseCatalog? catalog,
  Object? error,
  ExerciseMediaGender? mediaGender,
}) async {
  final controller = ExercisesController(
    repository: FakeExerciseCatalogRepository(
      catalog: catalog ?? syntheticCatalog(),
      error: error,
    ),
    mediaGender: mediaGender,
  );
  addTearDown(controller.dispose);
  await controller.load();
  return controller;
}

void main() {
  group('loading', () {
    test('starts loading and becomes ready with active Exercises', () async {
      final repository = FakeExerciseCatalogRepository(
        catalog: syntheticCatalog(),
        hold: true,
      );
      final controller = ExercisesController(repository: repository);
      addTearDown(controller.dispose);

      expect(controller.state.status, ExercisesStatus.loading);
      final loading = controller.load();
      expect(controller.state.status, ExercisesStatus.loading);

      repository.release();
      await loading;

      expect(controller.state.status, ExercisesStatus.ready);
      expect(refsOf(controller.state), [
        'ex_synthetic_curl',
        'ex_synthetic_press',
        'ex_synthetic_stretch',
      ]);
      expect(controller.state.hasActiveExercises, isTrue);
      expect(controller.state.isEmptyCatalog, isFalse);
      expect(controller.state.isNoMatch, isFalse);
    });

    test('an empty catalog is the empty state, not no-match', () async {
      final controller = await loadedController(
        catalog: ExerciseCatalog(const []),
      );

      expect(controller.state.status, ExercisesStatus.ready);
      expect(controller.state.isEmptyCatalog, isTrue);
      expect(controller.state.isNoMatch, isFalse);
    });

    test('a catalog of only archived Exercises is the empty state', () async {
      final controller = await loadedController(
        catalog: ExerciseCatalog([
          syntheticExercise(
            'ex_synthetic_old',
            'Synthetic Old',
            status: ExerciseStatus.archived,
          ),
        ]),
      );

      expect(controller.state.isEmptyCatalog, isTrue);
    });
  });

  group('failures', () {
    const stack = StackTrace.empty;
    final cases = <String, (Object, ExercisesStatus)>{
      'missing asset': (
        MissingExerciseCatalogAssetException(
          assetKey: exerciseCatalogAssetKey,
          cause: FlutterError('missing'),
          stackTrace: stack,
        ),
        ExercisesStatus.missingCatalog,
      ),
      'invalid document': (
        const InvalidExerciseCatalogDocumentException(
          path: r'$',
          problem: 'must be a JSON object',
        ),
        ExercisesStatus.malformedCatalog,
      ),
      'unsupported schema': (
        const UnsupportedExerciseCatalogSchemaVersionException(
          actual: 9,
          supported: 1,
        ),
        ExercisesStatus.malformedCatalog,
      ),
      'invalid rows': (
        InvalidExerciseCatalogException(const [
          ExerciseCatalogIssue(rowIndex: 0, path: 'id', problem: 'missing'),
        ]),
        ExercisesStatus.malformedCatalog,
      ),
      'asset load failure': (
        ExerciseCatalogAssetLoadException(
          assetKey: exerciseCatalogAssetKey,
          cause: PlatformException(code: 'io'),
          stackTrace: stack,
        ),
        ExercisesStatus.failed,
      ),
      'unexpected error': (StateError('boom'), ExercisesStatus.failed),
    };

    for (final entry in cases.entries) {
      test('${entry.key} maps to ${entry.value.$2.name}', () async {
        final controller = await loadedController(error: entry.value.$1);

        expect(controller.state.status, entry.value.$2);
        expect(controller.state.items, isEmpty);
      });
    }
  });

  group('search', () {
    test('matches display name through ExerciseCatalogQuery', () async {
      final controller = await loadedController();

      controller.setSearchText('  CURL ');

      expect(controller.state.query.text, '  CURL ');
      expect(refsOf(controller.state), ['ex_synthetic_curl']);
    });

    test('never surfaces archived Exercises', () async {
      final controller = await loadedController();

      controller.setSearchText('archived');

      expect(controller.state.items, isEmpty);
      expect(controller.state.isNoMatch, isTrue);
    });

    test('clearing the text restores every active Exercise', () async {
      final controller = await loadedController();
      controller.setSearchText('zzz');
      expect(controller.state.isNoMatch, isTrue);

      controller.setSearchText('');

      expect(refsOf(controller.state), hasLength(3));
    });

    test('an unchanged text does not notify', () async {
      final controller = await loadedController();
      var notifications = 0;
      controller.addListener(() => notifications++);

      controller.setSearchText('');

      expect(notifications, 0);
    });

    test('text typed while loading is kept once ready', () async {
      final repository = FakeExerciseCatalogRepository(
        catalog: syntheticCatalog(),
        hold: true,
      );
      final controller = ExercisesController(repository: repository);
      addTearDown(controller.dispose);
      final loading = controller.load();

      controller.setSearchText('press');
      repository.release();
      await loading;

      expect(refsOf(controller.state), ['ex_synthetic_press']);
    });
  });

  group('filters', () {
    test('muscle filter', () async {
      final controller = await loadedController();

      controller.applyFilters(muscleGroup: 'upper_arms');

      expect(refsOf(controller.state),
          ['ex_synthetic_curl', 'ex_synthetic_stretch']);
      expect(controller.state.activeFilterCount, 1);
      expect(
        controller.state.selectedValue(ExerciseFilterDimension.muscle),
        'upper_arms',
      );
    });

    test('equipment filter', () async {
      final controller = await loadedController();

      controller.applyFilters(primaryEquipment: 'ez_bar');

      expect(refsOf(controller.state), ['ex_synthetic_press']);
    });

    test('category filter', () async {
      final controller = await loadedController();

      controller.applyFilters(category: 'stretch');

      expect(refsOf(controller.state), ['ex_synthetic_stretch']);
    });

    test('filters combine with each other and with search', () async {
      final controller = await loadedController();

      controller
        ..setSearchText('synthetic')
        ..applyFilters(muscleGroup: 'upper_arms', category: 'strength');

      expect(refsOf(controller.state), ['ex_synthetic_curl']);
      expect(controller.state.activeFilterCount, 2);

      controller.setSearchText('stretch');
      expect(controller.state.isNoMatch, isTrue);
    });

    test('applying filters keeps the search text', () async {
      final controller = await loadedController();
      controller.setSearchText('curl');

      controller.applyFilters(category: 'strength');

      expect(controller.state.query.text, 'curl');
    });

    test('applying no filters clears every filter', () async {
      final controller = await loadedController();
      controller.applyFilters(muscleGroup: 'chest', category: 'strength');

      controller.applyFilters();

      expect(controller.state.activeFilterCount, 0);
      expect(refsOf(controller.state), hasLength(3));
    });

    test('options come from active Exercises, sorted by label', () async {
      final controller = await loadedController();
      final state = controller.state;

      expect(state.optionsFor(ExerciseFilterDimension.muscle), const [
        ExerciseFilterOption(value: 'chest', label: 'Chest'),
        ExerciseFilterOption(value: 'upper_arms', label: 'Upper arms'),
      ]);
      expect(state.optionsFor(ExerciseFilterDimension.equipment), const [
        ExerciseFilterOption(value: 'dumbbell', label: 'Dumbbell'),
        ExerciseFilterOption(value: 'ez_bar', label: 'EZ bar'),
      ]);
      expect(state.optionsFor(ExerciseFilterDimension.category), const [
        ExerciseFilterOption(value: 'strength', label: 'Strength'),
        ExerciseFilterOption(value: 'stretch', label: 'Stretch'),
      ]);
    });
  });

  group('rows', () {
    test('metadata reads Primary equipment • Muscle group', () async {
      final controller = await loadedController();
      final byRef = {
        for (final item in controller.state.items)
          item.exercise.ref.value: item,
      };

      expect(byRef['ex_synthetic_curl']!.metadata, 'Dumbbell • Upper arms');
      expect(byRef['ex_synthetic_press']!.metadata, 'EZ bar • Chest');
      expect(byRef['ex_synthetic_stretch']!.metadata, 'Upper arms');
      expect(byRef['ex_synthetic_curl']!.name, 'Synthetic Curl');
    });

    test('metadata is null without equipment or muscle group', () {
      expect(
        ExercisesController.metadataFor(
          syntheticExercise('ex_synthetic_bare', 'Synthetic Bare'),
        ),
        isNull,
      );
    });

    test('thumbnail follows the viewer gender through urlFor', () async {
      final unknown = await loadedController();
      final female = await loadedController(
        mediaGender: ExerciseMediaGender.female,
      );

      expect(
        unknown.state.items.first.thumbnailUrl,
        Uri.parse('https://media.example/curl-male.png'),
        reason: 'unknown gender uses defaultGender',
      );
      expect(
        female.state.items.first.thumbnailUrl,
        Uri.parse('https://media.example/curl-female.png'),
      );
    });

    test('thumbnail falls back to the thumbnail kind, then to none', () async {
      final controller = await loadedController(
        mediaGender: ExerciseMediaGender.female,
      );
      final byRef = {
        for (final item in controller.state.items)
          item.exercise.ref.value: item,
      };

      expect(
        byRef['ex_synthetic_press']!.thumbnailUrl,
        Uri.parse('https://media.example/press-female-thumb.jpg'),
      );
      expect(byRef['ex_synthetic_stretch']!.thumbnailUrl, isNull);
    });

    test('a missing viewer variant falls back through urlFor', () {
      final exercise = syntheticExercise(
        'ex_synthetic_only_male',
        'Synthetic Only Male',
        media: syntheticMedia('only-male', femaleImage: false),
      );

      expect(
        ExercisesController.thumbnailUrlFor(
          exercise,
          gender: ExerciseMediaGender.female,
        ),
        Uri.parse('https://media.example/only-male-male.png'),
      );
    });

    test('changing media gender re-resolves rows and keeps the query',
        () async {
      final controller = await loadedController();
      controller.setSearchText('curl');

      controller.setMediaGender(ExerciseMediaGender.female);

      expect(controller.mediaGender, ExerciseMediaGender.female);
      expect(controller.state.query.text, 'curl');
      expect(
        controller.state.items.single.thumbnailUrl,
        Uri.parse('https://media.example/curl-female.png'),
      );
    });
  });

  test('no notifications after dispose', () async {
    final repository = FakeExerciseCatalogRepository(
      catalog: syntheticCatalog(),
      hold: true,
    );
    final controller = ExercisesController(repository: repository);
    final loading = controller.load();
    controller.dispose();

    repository.release();
    await expectLater(loading, completes);
  });

  test('taxonomy labels', () {
    expect(exerciseTaxonomyLabel('upper_arms'), 'Upper arms');
    expect(exerciseTaxonomyLabel('lever_machine'), 'Lever machine');
    expect(exerciseTaxonomyLabel('ez_bar'), 'EZ bar');
    expect(exerciseTaxonomyLabel('cardio'), 'Cardio');
  });
}

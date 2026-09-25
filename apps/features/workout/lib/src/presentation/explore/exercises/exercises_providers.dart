import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_shared/shared.dart';

import '../../../data/exercises/asset_bundle_exercise_catalog_source.dart';
import '../../../domain/exercises/exercise_catalog_repository.dart';
import 'exercises_controller.dart';

/// Production built-in Exercise catalog: the Workout-owned bundled asset.
final exerciseCatalogRepositoryProvider = Provider<ExerciseCatalogRepository>(
  (ref) => AssetBundleExerciseCatalogSource(rootBundle),
);

/// The viewer's media gender for Exercise images.
///
/// Null means unknown, so media falls back to each Exercise's
/// `defaultGender`. The app composition root overrides this from the
/// signed-in profile; Workout does not read Profile itself.
final exerciseViewerMediaGenderProvider =
    Provider<ExerciseMediaGender?>((ref) => null);

final exercisesControllerProvider =
    ChangeNotifierProvider.autoDispose<ExercisesController>((ref) {
  final controller = ExercisesController(
    repository: ref.watch(exerciseCatalogRepositoryProvider),
    mediaGender: ref.read(exerciseViewerMediaGenderProvider),
  );
  // A profile that loads after the screen opens re-resolves thumbnails
  // without reloading the catalog or clearing the search.
  ref.listen<ExerciseMediaGender?>(
    exerciseViewerMediaGenderProvider,
    (_, gender) => controller.setMediaGender(gender),
  );
  controller.load();
  return controller;
});

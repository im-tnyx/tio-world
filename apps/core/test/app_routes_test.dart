import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  test('Additional Nutrition route describes the read-only reference surface',
      () {
    expect(
      AppRoutes.nutritionAdditionalGoalsSettings.description,
      'View calculated daily reference values for additional nutrients.',
    );
    expect(
      AppRoutes.nutritionAdditionalGoalsSettings.path,
      '/settings/nutrition/targets/additional-goals',
      reason: 'The compatibility path is unchanged.',
    );
  });

  test('Meal Diary Settings routes keep one nested settings hierarchy', () {
    expect(
      AppRoutes.mealDiarySettings.path,
      '/settings/nutrition/meal-diary',
    );
    expect(
      AppRoutes.mealCategoriesSettings.path,
      '/settings/nutrition/meal-diary/categories',
    );
    expect(
      AppRoutes.mealCategoriesSettings.path
          .startsWith('${AppRoutes.mealDiarySettings.path}/'),
      isTrue,
    );
    expect(
      AppRoutes.archivedMealCategoriesSettings.path,
      '/settings/nutrition/meal-diary/categories/archived',
    );
    expect(
      AppRoutes.archivedMealCategoriesSettings.path
          .startsWith('${AppRoutes.mealCategoriesSettings.path}/'),
      isTrue,
      reason: 'archived categories nest under the categories they came from',
    );
    expect(AppRoutes.mealDiarySettings.chromePolicy, ChromePolicy.fullScreen);
    expect(
      AppRoutes.mealCategoriesSettings.chromePolicy,
      ChromePolicy.fullScreen,
    );
    expect(
      AppRoutes.archivedMealCategoriesSettings.chromePolicy,
      ChromePolicy.fullScreen,
    );
  });

  test('Programs route nests under the Workout branch without bottom nav', () {
    expect(AppRoutes.workoutPrograms.path, '/workout/programs');
    expect(
      AppRoutes.workoutPrograms.path
          .startsWith('${FeatureRoutes.workout.path}/'),
      isTrue,
    );
    expect(AppRoutes.workoutPrograms.title, 'Programs');
    expect(AppRoutes.workoutPrograms.chromePolicy, ChromePolicy.noBottomBar);
    expect(AppRoutes.workoutPrograms.chromePolicy.showsBottomNav, isFalse);
  });

  test('Exercises route nests under the Workout branch without bottom nav', () {
    expect(AppRoutes.workoutExercises.path, '/workout/exercises');
    expect(
      AppRoutes.workoutExercises.path
          .startsWith('${FeatureRoutes.workout.path}/'),
      isTrue,
    );
    expect(AppRoutes.workoutExercises.title, 'Exercises');
    expect(
      AppRoutes.workoutExercises.chromePolicy,
      ChromePolicy.noBottomBar,
    );
    expect(AppRoutes.workoutExercises.chromePolicy.showsBottomNav, isFalse);
  });

  test('Active Workout route nests under Workout without bottom nav', () {
    expect(AppRoutes.workoutActive.path, '/workout/active');
    expect(
      AppRoutes.workoutActive.path.startsWith('${FeatureRoutes.workout.path}/'),
      isTrue,
    );
    expect(AppRoutes.workoutActive.title, 'Active Workout');
    expect(AppRoutes.workoutActive.chromePolicy, ChromePolicy.noBottomBar);
    expect(AppRoutes.workoutActive.chromePolicy.showsBottomNav, isFalse);
  });

  test('History route nests under Workout without bottom nav', () {
    expect(AppRoutes.workoutHistory.path, '/workout/history');
    expect(
        AppRoutes.workoutHistory.path
            .startsWith('${FeatureRoutes.workout.path}/'),
        isTrue);
    expect(AppRoutes.workoutHistory.title, 'History');
    expect(AppRoutes.workoutHistory.chromePolicy, ChromePolicy.noBottomBar);
    expect(AppRoutes.workoutHistoryDetail.path, '/workout/history/:sessionId');
    expect(
        AppRoutes.workoutHistoryDetail.chromePolicy, ChromePolicy.noBottomBar);
    expect(AppRoutes.workoutHistoryEdit.path,
        '/workout/history/:sessionId/edit');
    expect(AppRoutes.workoutHistoryEdit.chromePolicy,
        ChromePolicy.noBottomBar);
  });

  test('Exercise Detail route nests under Exercises without bottom nav', () {
    expect(
      AppRoutes.workoutExerciseDetail.path,
      '/workout/exercises/:exerciseId',
    );
    expect(
      AppRoutes.workoutExerciseDetail.path
          .startsWith('${FeatureRoutes.workout.path}/'),
      isTrue,
    );
    expect(AppRoutes.workoutExerciseDetail.title, 'Exercise Detail');
    expect(
      AppRoutes.workoutExerciseDetail.chromePolicy,
      ChromePolicy.noBottomBar,
    );
    expect(
      AppRoutes.workoutExerciseDetail.chromePolicy.showsBottomNav,
      isFalse,
    );
  });

  test('Library route nests under the Workout branch without bottom nav', () {
    expect(AppRoutes.workoutLibrary.path, '/workout/library');
    expect(
      AppRoutes.workoutLibrary.path
          .startsWith('${FeatureRoutes.workout.path}/'),
      isTrue,
    );
    expect(AppRoutes.workoutLibrary.title, 'Library');
    expect(AppRoutes.workoutLibrary.chromePolicy, ChromePolicy.noBottomBar);
  });
}

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/shared_preferences_meal_diary_display_preferences_repository.dart';
import 'domain/repositories/meal_diary_display_preferences_repository.dart';
import 'presentation/controllers/meal_diary_display_preferences_controller.dart';

/// Feature-level composition seam for Meal Diary display preferences.
///
/// Keeping concrete storage construction here prevents presentation/controller
/// code from depending on the data adapter. Production app bootstrap overrides
/// the controller provider with the same preloaded instance used at startup.
final mealDiaryDisplayPreferencesRepositoryProvider =
    Provider<MealDiaryDisplayPreferencesRepository>(
  (ref) => SharedPreferencesMealDiaryDisplayPreferencesRepository(),
);

final mealDiaryDisplayPreferencesControllerProvider =
    ChangeNotifierProvider<MealDiaryDisplayPreferencesController>((ref) {
  final controller = MealDiaryDisplayPreferencesController(
    ref.watch(mealDiaryDisplayPreferencesRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  unawaited(controller.load());
  return controller;
});

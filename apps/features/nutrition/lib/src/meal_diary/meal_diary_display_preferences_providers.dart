import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'domain/models/meal_diary_display_preferences.dart';
import 'domain/repositories/meal_diary_display_preferences_repository.dart';
import 'presentation/controllers/meal_diary_display_preferences_controller.dart';

/// Feature-level composition seam for Meal Diary display preferences.
///
/// The package default is intentionally platform-neutral so feature/app router
/// harnesses can render the Settings destination without a plugin platform.
/// Production app bootstrap constructs the device-local SharedPreferences
/// adapter, preloads its controller, and overrides the controller provider with
/// that same instance before the first frame.
final mealDiaryDisplayPreferencesRepositoryProvider =
    Provider<MealDiaryDisplayPreferencesRepository>(
  (ref) => _InMemoryMealDiaryDisplayPreferencesRepository(),
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

final class _InMemoryMealDiaryDisplayPreferencesRepository
    implements MealDiaryDisplayPreferencesRepository {
  MealDiaryDisplayPreferences _value = const MealDiaryDisplayPreferences();

  @override
  Future<MealDiaryDisplayPreferences> read() async => _value;

  @override
  Future<void> write(MealDiaryDisplayPreferences preferences) async {
    _value = preferences;
  }

  @override
  Future<void> clear() async {
    _value = const MealDiaryDisplayPreferences();
  }
}

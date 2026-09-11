import '../models/meal_diary_display_preferences.dart';

/// Persistence boundary for device-local Meal Diary presentation preferences.
abstract interface class MealDiaryDisplayPreferencesRepository {
  Future<MealDiaryDisplayPreferences> read();

  Future<void> write(MealDiaryDisplayPreferences preferences);

  Future<void> clear();
}

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models/meal_diary_display_preferences.dart';
import '../domain/repositories/meal_diary_display_preferences_repository.dart';

/// Device-local storage for Meal Diary presentation preferences.
///
/// The three values are encoded under one versioned key so one user action
/// writes one coherent snapshot. They are display/capability preferences, not
/// account-synced nutrition truth, and therefore do not belong in Supabase.
final class SharedPreferencesMealDiaryDisplayPreferencesRepository
    implements MealDiaryDisplayPreferencesRepository {
  SharedPreferencesMealDiaryDisplayPreferencesRepository({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'nutrition_meal_diary_display_preferences_v1';
  static const _schemaVersion = 1;

  final SharedPreferencesAsync _preferences;

  @override
  Future<MealDiaryDisplayPreferences> read() async {
    String? raw;
    try {
      raw = await _preferences.getString(storageKey);
    } on TypeError {
      await _preferences.remove(storageKey);
      return const MealDiaryDisplayPreferences();
    }

    if (raw == null) return const MealDiaryDisplayPreferences();

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != _schemaVersion ||
          decoded['showMealTimes'] is! bool ||
          decoded['mealNotesEnabled'] is! bool ||
          decoded['showMealNotePreview'] is! bool) {
        throw const FormatException('Invalid Meal Diary preferences payload.');
      }

      // Added after schema version 1 already shipped. An older stored payload
      // predates this key, so its absence is the expected legacy shape, not
      // corruption — only a present-but-wrong-typed value fails closed like
      // the other fields above.
      final sectionNutritionRaw = decoded['showMealSectionNutrition'];
      if (sectionNutritionRaw != null && sectionNutritionRaw is! bool) {
        throw const FormatException('Invalid Meal Diary preferences payload.');
      }

      return MealDiaryDisplayPreferences(
        showMealTimes: decoded['showMealTimes'] as bool,
        mealNotesEnabled: decoded['mealNotesEnabled'] as bool,
        showMealNotePreview: decoded['showMealNotePreview'] as bool,
        showMealSectionNutrition: sectionNutritionRaw as bool? ?? true,
      );
    } on FormatException {
      await _preferences.remove(storageKey);
      return const MealDiaryDisplayPreferences();
    } on TypeError {
      await _preferences.remove(storageKey);
      return const MealDiaryDisplayPreferences();
    }
  }

  @override
  Future<void> write(MealDiaryDisplayPreferences preferences) {
    return _preferences.setString(
      storageKey,
      jsonEncode({
        'version': _schemaVersion,
        'showMealTimes': preferences.showMealTimes,
        'mealNotesEnabled': preferences.mealNotesEnabled,
        'showMealNotePreview': preferences.showMealNotePreview,
        'showMealSectionNutrition': preferences.showMealSectionNutrition,
      }),
    );
  }

  @override
  Future<void> clear() => _preferences.remove(storageKey);
}

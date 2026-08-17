import '../models/workout_preferences_data.dart';

/// Canonical repository contract for persisting and retrieving workout preferences setup data.
abstract interface class WorkoutPreferencesRepository {
  /// Persists or updates the complete user workout preferences.
  Future<void> saveWorkoutPreferences(WorkoutPreferencesData data);

  /// Retrieves the persisted workout preferences, or null if not yet saved.
  Future<WorkoutPreferencesData?> getWorkoutPreferences();
}

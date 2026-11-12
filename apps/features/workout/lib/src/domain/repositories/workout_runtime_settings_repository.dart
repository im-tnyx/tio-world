/// Device-local Workout preferences. These values are not account data and
/// must never be persisted through the Workout/Supabase repositories.
abstract interface class WorkoutRuntimeSettingsRepository {
  /// Returns null when no preference has been saved, or 0 for explicit OFF.
  Future<int?> readDefaultRestSeconds();

  /// Saves 0 for explicit OFF, or a supported positive duration.
  Future<void> writeDefaultRestSeconds(int seconds);

  Future<void> clearDefaultRestSeconds();
}

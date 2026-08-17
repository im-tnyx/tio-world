import '../domain/models/workout_preferences_data.dart';
import '../domain/repositories/workout_preferences_repository.dart';

/// Thread-safe in-memory implementation of [WorkoutPreferencesRepository].
class InMemoryWorkoutPreferencesRepository
    implements WorkoutPreferencesRepository {
  InMemoryWorkoutPreferencesRepository({WorkoutPreferencesData? initialData})
      : _data = initialData;

  WorkoutPreferencesData? _data;

  @override
  Future<void> saveWorkoutPreferences(WorkoutPreferencesData data) async {
    _data = data;
  }

  @override
  Future<WorkoutPreferencesData?> getWorkoutPreferences() async {
    return _data;
  }
}

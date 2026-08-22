import '../domain/models/workout_profile_data.dart';
import '../domain/repositories/workout_profile_repository.dart';

class InMemoryWorkoutProfileRepository implements WorkoutProfileRepository {
  WorkoutProfileData? _data;

  WorkoutProfileData? get data => _data;

  @override
  Future<WorkoutProfileData?> read() async => _data;

  @override
  Future<void> upsert(WorkoutProfileData profile) async {
    _data = profile;
  }
}

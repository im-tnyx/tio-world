import '../models/workout_profile_data.dart';

abstract interface class WorkoutProfileRepository {
  Future<WorkoutProfileData?> read();

  Future<void> upsert(WorkoutProfileData profile);
}

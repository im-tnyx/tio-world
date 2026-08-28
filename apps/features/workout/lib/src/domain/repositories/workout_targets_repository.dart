import '../models/workout_targets_data.dart';

abstract interface class WorkoutTargetsRepository {
  Future<WorkoutTargetsData?> read();

  Future<void> upsert(WorkoutTargetsData targets);
}

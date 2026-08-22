import '../domain/models/workout_targets_data.dart';
import '../domain/repositories/workout_targets_repository.dart';

class InMemoryWorkoutTargetsRepository implements WorkoutTargetsRepository {
  WorkoutTargetsData? _data;

  WorkoutTargetsData? get data => _data;

  @override
  Future<WorkoutTargetsData?> read() async => _data;

  @override
  Future<void> upsert(WorkoutTargetsData targets) async {
    targets.validate();
    _data = targets;
  }
}

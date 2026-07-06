import '../models/models.dart';

abstract interface class WorkoutRepository {
  Future<List<Workout>> getWorkouts();

  Future<Workout?> getWorkoutById(String id);

  Future<List<Exercise>> getExercises();

  Future<TrainingSession> startWorkout(String workoutId);

  Future<void> saveSet(WorkoutSet set);

  Future<void> finishTrainingSession(String sessionId);
}

import '../models/active_workout_draft.dart';
import '../models/workout_history_entry.dart';

/// One requested replacement of an already completed, owner-owned workout.
/// The server compares [source]'s revision and retains its canonical ID.
final class WorkoutHistoryEditRequest {
  const WorkoutHistoryEditRequest({
    required this.source,
    required this.title,
    required this.description,
    required this.workoutAtUtc,
    required this.utcOffsetMinutes,
    required this.durationSeconds,
    required this.gymName,
    required this.activityType,
    required this.overallRpe,
    required this.exercises,
  });

  final WorkoutHistoryDetail source;
  final String title;
  final String? description;
  final DateTime workoutAtUtc;
  final int utcOffsetMinutes;
  final int durationSeconds;
  final String? gymName;
  final String? activityType;
  final double? overallRpe;
  final List<ActiveWorkoutDraftExercise> exercises;
}

abstract interface class WorkoutHistoryEditRepository {
  Future<WorkoutHistoryDetail> updateCompletedWorkout(
    WorkoutHistoryEditRequest request,
  );
}

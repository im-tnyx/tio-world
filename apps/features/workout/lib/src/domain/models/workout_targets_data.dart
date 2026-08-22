import 'workout_split.dart';
import 'workout_target_goal.dart';
import 'workout_training_day.dart';

/// Canonical Workout goals, schedule and plan constraints owned by
/// `user_workout_targets`.
class WorkoutTargetsData {
  const WorkoutTargetsData({
    this.primaryWorkoutGoal,
    this.primaryGoalRank,
    this.supportingWorkoutGoal,
    this.supportingGoalRank,
    this.trainingDays = const {},
    this.preferredDurationMins,
    this.splitProgram,
    this.specialEvent,
    this.specialEventDate,
  });

  final WorkoutTargetGoal? primaryWorkoutGoal;
  final int? primaryGoalRank;
  final WorkoutTargetGoal? supportingWorkoutGoal;
  final int? supportingGoalRank;
  final Set<WorkoutTrainingDay> trainingDays;
  final int? preferredDurationMins;
  final WorkoutSplit? splitProgram;
  final String? specialEvent;
  final DateTime? specialEventDate;

  /// Mirrors the live `user_workout_targets` constraints without inventing
  /// additional product defaults.
  void validate() {
    _validateRank(primaryGoalRank, 'primaryGoalRank');
    _validateRank(supportingGoalRank, 'supportingGoalRank');

    if (primaryGoalRank != null && primaryWorkoutGoal == null) {
      throw ArgumentError(
        'primaryGoalRank requires primaryWorkoutGoal.',
        'primaryGoalRank',
      );
    }
    if (supportingGoalRank != null && supportingWorkoutGoal == null) {
      throw ArgumentError(
        'supportingGoalRank requires supportingWorkoutGoal.',
        'supportingGoalRank',
      );
    }
    if (supportingWorkoutGoal != null && primaryWorkoutGoal == null) {
      throw ArgumentError(
        'supportingWorkoutGoal requires primaryWorkoutGoal.',
        'supportingWorkoutGoal',
      );
    }
    if (primaryWorkoutGoal != null &&
        supportingWorkoutGoal != null &&
        primaryWorkoutGoal == supportingWorkoutGoal) {
      throw ArgumentError(
        'Primary and supporting Workout goals must be distinct.',
        'supportingWorkoutGoal',
      );
    }
    if (primaryGoalRank != null &&
        supportingGoalRank != null &&
        primaryGoalRank == supportingGoalRank) {
      throw ArgumentError(
        'Primary and supporting Workout goal ranks must be distinct.',
        'supportingGoalRank',
      );
    }
    if (preferredDurationMins != null && preferredDurationMins! <= 0) {
      throw ArgumentError.value(
        preferredDurationMins,
        'preferredDurationMins',
        'Expected a positive duration when present.',
      );
    }
  }
}

void _validateRank(int? rank, String name) {
  if (rank != null && rank != 1 && rank != 2) {
    throw ArgumentError.value(rank, name, 'Expected rank 1 or 2 when present.');
  }
}

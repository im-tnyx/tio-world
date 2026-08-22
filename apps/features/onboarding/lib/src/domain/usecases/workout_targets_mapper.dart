import 'package:tio_feature_workout/workout.dart' as workout_owner;

import '../models/models.dart';

/// Maps Product Onboarding Workout answers to the canonical Workout Targets
/// owner contract without fabricating goals, durations or event dates.
class WorkoutTargetsMapper {
  const WorkoutTargetsMapper();

  workout_owner.WorkoutTargetsData map(OnboardingDraft draft) {
    final rankedGoals = <_RankedWorkoutGoal>[];
    final primaryGoal = _mapGoal(draft.goalSelection.primaryGoal);
    if (primaryGoal != null) {
      rankedGoals.add(_RankedWorkoutGoal(goal: primaryGoal, rank: 1));
    }
    final supportingGoal = _mapGoal(draft.goalSelection.supportingGoal);
    if (supportingGoal != null) {
      rankedGoals.add(_RankedWorkoutGoal(goal: supportingGoal, rank: 2));
    }

    final first = rankedGoals.isEmpty ? null : rankedGoals.first;
    final second = rankedGoals.length < 2 ? null : rankedGoals[1];
    final specialEvent = draft.workout.specialEvent.trim();

    final data = workout_owner.WorkoutTargetsData(
      primaryWorkoutGoal: first?.goal,
      primaryGoalRank: first?.rank,
      supportingWorkoutGoal: second?.goal,
      supportingGoalRank: second?.rank,
      trainingDays: draft.workout.trainingDays.map(_mapTrainingDay).toSet(),
      preferredDurationMins: _mapDuration(draft.workout.workoutDuration),
      splitProgram: _mapSplit(draft.workout.workoutSplit),
      specialEvent: specialEvent.isEmpty ? null : specialEvent,
      specialEventDate: null,
    );
    data.validate();
    return data;
  }

  workout_owner.WorkoutTargetGoal? _mapGoal(GoalIntent? goal) => switch (goal) {
        GoalIntent.buildMuscle => workout_owner.WorkoutTargetGoal.buildMuscle,
        GoalIntent.getStronger => workout_owner.WorkoutTargetGoal.getStronger,
        GoalIntent.improveEndurance =>
          workout_owner.WorkoutTargetGoal.improveEndurance,
        GoalIntent.stayFit => workout_owner.WorkoutTargetGoal.stayFit,
        GoalIntent.loseWeight ||
        GoalIntent.gainWeight ||
        GoalIntent.maintainWeight ||
        GoalIntent.recomposition ||
        null =>
          null,
      };

  workout_owner.WorkoutTrainingDay _mapTrainingDay(WorkoutTrainingDay day) =>
      switch (day) {
        WorkoutTrainingDay.monday => workout_owner.WorkoutTrainingDay.monday,
        WorkoutTrainingDay.tuesday => workout_owner.WorkoutTrainingDay.tuesday,
        WorkoutTrainingDay.wednesday =>
          workout_owner.WorkoutTrainingDay.wednesday,
        WorkoutTrainingDay.thursday => workout_owner.WorkoutTrainingDay.thursday,
        WorkoutTrainingDay.friday => workout_owner.WorkoutTrainingDay.friday,
        WorkoutTrainingDay.saturday => workout_owner.WorkoutTrainingDay.saturday,
        WorkoutTrainingDay.sunday => workout_owner.WorkoutTrainingDay.sunday,
      };

  int? _mapDuration(WorkoutDuration? duration) => switch (duration) {
        null || WorkoutDuration.auto => null,
        WorkoutDuration.thirtyMinutes => 30,
        WorkoutDuration.sixtyMinutes => 60,
        WorkoutDuration.ninetyMinutes => 90,
        WorkoutDuration.oneHundredTwentyMinutes => 120,
      };

  workout_owner.WorkoutSplit? _mapSplit(WorkoutSplit? split) => switch (split) {
        null => null,
        WorkoutSplit.auto => workout_owner.WorkoutSplit.auto,
        WorkoutSplit.fullBody => workout_owner.WorkoutSplit.fullBody,
        WorkoutSplit.upperLower => workout_owner.WorkoutSplit.upperLower,
        WorkoutSplit.ppl => workout_owner.WorkoutSplit.ppl,
        WorkoutSplit.bodyPart => workout_owner.WorkoutSplit.bodyPart,
      };
}

class _RankedWorkoutGoal {
  const _RankedWorkoutGoal({required this.goal, required this.rank});

  final workout_owner.WorkoutTargetGoal goal;
  final int rank;
}

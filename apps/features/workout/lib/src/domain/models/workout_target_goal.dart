/// Canonical training intent persisted by `user_workout_targets`.
enum WorkoutTargetGoal {
  buildMuscle,
  getStronger,
  improveEndurance,
  stayFit,
}

extension WorkoutTargetGoalStorage on WorkoutTargetGoal {
  String get storageValue => switch (this) {
        WorkoutTargetGoal.buildMuscle => 'build_muscle',
        WorkoutTargetGoal.getStronger => 'get_stronger',
        WorkoutTargetGoal.improveEndurance => 'improve_endurance',
        WorkoutTargetGoal.stayFit => 'stay_fit',
      };
}

WorkoutTargetGoal parseWorkoutTargetGoal(Object? raw) {
  return switch (raw) {
    'build_muscle' => WorkoutTargetGoal.buildMuscle,
    'get_stronger' => WorkoutTargetGoal.getStronger,
    'improve_endurance' => WorkoutTargetGoal.improveEndurance,
    'stay_fit' => WorkoutTargetGoal.stayFit,
    _ => throw FormatException('Invalid canonical Workout target goal: $raw'),
  };
}

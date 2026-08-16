enum WorkoutDuration {
  auto,
  thirtyMinutes,
  sixtyMinutes,
  ninetyMinutes,
  oneHundredTwentyMinutes;

  int? get minutes => switch (this) {
        WorkoutDuration.auto => null,
        WorkoutDuration.thirtyMinutes => 30,
        WorkoutDuration.sixtyMinutes => 60,
        WorkoutDuration.ninetyMinutes => 90,
        WorkoutDuration.oneHundredTwentyMinutes => 120,
      };
}

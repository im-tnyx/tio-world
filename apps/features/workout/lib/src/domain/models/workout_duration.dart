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

  static WorkoutDuration fromMinutes(int? minutes) => switch (minutes) {
        null => WorkoutDuration.auto,
        30 => WorkoutDuration.thirtyMinutes,
        60 => WorkoutDuration.sixtyMinutes,
        90 => WorkoutDuration.ninetyMinutes,
        120 => WorkoutDuration.oneHundredTwentyMinutes,
        _ => throw FormatException(
            'Unsupported workout duration minutes: $minutes'),
      };
}

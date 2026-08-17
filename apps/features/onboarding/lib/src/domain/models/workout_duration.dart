enum WorkoutDuration {
  auto('auto'),
  thirtyMinutes('30_min'),
  sixtyMinutes('60_min'),
  ninetyMinutes('90_min'),
  oneHundredTwentyMinutes('120_min');

  const WorkoutDuration(this.storageValue);

  final String storageValue;

  static WorkoutDuration? fromStorageValue(String? value) {
    for (final duration in WorkoutDuration.values) {
      if (duration.storageValue == value) return duration;
    }
    return null;
  }
}

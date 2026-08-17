enum WorkoutExperienceLevel {
  fresh('fresh'),
  beginner('beginner'),
  intermediate('intermediate'),
  advanced('advanced');

  const WorkoutExperienceLevel(this.storageValue);

  final String storageValue;

  static WorkoutExperienceLevel? fromStorageValue(String? value) {
    for (final level in WorkoutExperienceLevel.values) {
      if (level.storageValue == value) return level;
    }
    return null;
  }
}

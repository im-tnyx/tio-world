enum WorkoutGymAccess {
  gym('gym'),
  home('home');

  const WorkoutGymAccess(this.storageValue);

  final String storageValue;

  static WorkoutGymAccess? fromStorageValue(String? value) {
    for (final access in WorkoutGymAccess.values) {
      if (access.storageValue == value) return access;
    }
    return null;
  }
}

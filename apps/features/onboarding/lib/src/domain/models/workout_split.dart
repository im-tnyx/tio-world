enum WorkoutSplit {
  auto('auto'),
  fullBody('full_body'),
  upperLower('upper_lower'),
  ppl('ppl'),
  bodyPart('body_part');

  const WorkoutSplit(this.storageValue);

  final String storageValue;

  static WorkoutSplit? fromStorageValue(String? value) {
    for (final split in WorkoutSplit.values) {
      if (split.storageValue == value) return split;
    }
    return null;
  }
}

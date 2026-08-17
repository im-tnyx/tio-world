enum WorkoutTrainingDay {
  monday('monday'),
  tuesday('tuesday'),
  wednesday('wednesday'),
  thursday('thursday'),
  friday('friday'),
  saturday('saturday'),
  sunday('sunday');

  const WorkoutTrainingDay(this.storageValue);

  final String storageValue;

  static WorkoutTrainingDay? fromStorageValue(String? value) {
    for (final day in WorkoutTrainingDay.values) {
      if (day.storageValue == value) return day;
    }
    return null;
  }
}

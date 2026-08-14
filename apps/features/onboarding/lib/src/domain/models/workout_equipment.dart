enum WorkoutEquipment {
  dumbbells('dumbbells'),
  bench('bench'),
  mat('mat'),
  barbell('barbell'),
  bands('bands'),
  kettlebell('kettlebell');

  const WorkoutEquipment(this.storageValue);

  final String storageValue;

  static WorkoutEquipment? fromStorageValue(String? value) {
    for (final equipment in WorkoutEquipment.values) {
      if (equipment.storageValue == value) return equipment;
    }
    return null;
  }
}

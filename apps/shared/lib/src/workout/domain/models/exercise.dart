class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    this.primaryMuscleGroup,
    this.equipment,
  });

  final String id;
  final String name;
  final String? primaryMuscleGroup;
  final String? equipment;
}

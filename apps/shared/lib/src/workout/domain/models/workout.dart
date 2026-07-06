class Workout {
  const Workout({
    required this.id,
    required this.name,
    this.description,
    this.exerciseIds = const [],
  });

  final String id;
  final String name;
  final String? description;
  final List<String> exerciseIds;
}

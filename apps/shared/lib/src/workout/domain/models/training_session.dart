class TrainingSession {
  const TrainingSession({
    required this.id,
    required this.workoutId,
    required this.startedAt,
    this.endedAt,
  });

  final String id;
  final String workoutId;
  final DateTime startedAt;
  final DateTime? endedAt;

  bool get isOpen => endedAt == null;
}

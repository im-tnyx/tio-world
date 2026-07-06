import 'set_type.dart';

class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.exerciseId,
    required this.reps,
    this.weight,
    this.type = SetType.working,
    this.completedAt,
  });

  final String id;
  final String exerciseId;
  final int reps;
  final double? weight;
  final SetType type;
  final DateTime? completedAt;
}

import 'workout_id_validation.dart';

/// Durable identity of a user-owned Routine.
///
/// A distinct type over a canonical UUID so it cannot be substituted for
/// Program, TrainingPlan, PlannedWorkout or WorkoutSession identity.
final class RoutineId {
  /// Accepts canonical UUID text of any version and stores it lowercase.
  factory RoutineId(String value) =>
      RoutineId._(requireCanonicalUuid(value, 'value'));

  const RoutineId._(this.value);

  /// Lowercase canonical UUID.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is RoutineId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

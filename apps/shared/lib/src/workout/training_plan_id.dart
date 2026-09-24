import 'workout_id_validation.dart';

/// Durable identity of a user's TrainingPlan instance.
///
/// A distinct type over a canonical UUID so it cannot be passed where another
/// Workout identity is expected. It carries identity only; the entity itself,
/// its persistence and its lifecycle belong to later slices.
final class TrainingPlanId {
  /// Accepts canonical UUID text of any version and stores it lowercase.
  factory TrainingPlanId(String value) =>
      TrainingPlanId._(requireCanonicalUuid(value, 'value'));

  const TrainingPlanId._(this.value);

  /// Lowercase canonical UUID.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TrainingPlanId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

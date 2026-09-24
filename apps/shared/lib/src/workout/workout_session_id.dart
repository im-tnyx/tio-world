import 'workout_id_validation.dart';

/// Durable identity of one WorkoutSession.
///
/// A distinct type over a canonical UUID so it cannot be passed where another
/// Workout identity is expected. It carries identity only; the entity itself,
/// its persistence and its lifecycle belong to later slices.
final class WorkoutSessionId {
  /// Accepts canonical UUID text of any version and stores it lowercase.
  factory WorkoutSessionId(String value) =>
      WorkoutSessionId._(requireCanonicalUuid(value, 'value'));

  const WorkoutSessionId._(this.value);

  /// Lowercase canonical UUID.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

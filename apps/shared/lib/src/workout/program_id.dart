import 'workout_id_validation.dart';

/// Durable identity of a user-owned Program.
///
/// A distinct type over a canonical UUID so it cannot be passed where another
/// Workout identity is expected. It carries identity only; persistence,
/// provenance and lifecycle belong to later slices.
final class ProgramId {
  /// Accepts canonical UUID text of any version and stores it lowercase.
  factory ProgramId(String value) =>
      ProgramId._(requireCanonicalUuid(value, 'value'));

  const ProgramId._(this.value);

  /// Lowercase canonical UUID.
  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProgramId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

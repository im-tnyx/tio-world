import 'program_id.dart';
import 'routine_id.dart';

/// Minimal canonical pure-Dart contract for one user-owned Routine.
///
/// A saved Routine has stable identity and belongs to exactly one user-owned
/// Program. Composition, persistence, provenance, media and lifecycle belong
/// to later bounded slices.
final class Routine {
  Routine({
    required this.id,
    required this.programId,
    required String name,
  }) : name = _requireNonBlankName(name);

  /// Stable identity of this user-owned Routine.
  final RoutineId id;

  /// Stable identity of the Program that owns this Routine.
  final ProgramId programId;

  /// Human-readable Routine name.
  final String name;

  static String _requireNonBlankName(String value) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        'name',
        'must contain at least one non-whitespace character',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Routine &&
          other.id == id &&
          other.programId == programId &&
          other.name == name;

  @override
  int get hashCode => Object.hash(id, programId, name);
}

import 'program_id.dart';

/// Minimal canonical pure-Dart contract for one user-owned Program.
///
/// This slice intentionally owns only stable identity and a non-blank name.
/// Routine composition, persistence, provenance, media and scheduling belong
/// to later bounded slices.
final class Program {
  Program({
    required this.id,
    required String name,
  }) : name = _requireNonBlankName(name);

  /// Stable identity of this user-owned Program.
  final ProgramId id;

  /// Human-readable Program name.
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
      other is Program && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

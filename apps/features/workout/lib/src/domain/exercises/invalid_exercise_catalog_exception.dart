/// One validation problem found in a built-in Exercise catalog row.
final class ExerciseCatalogIssue {
  const ExerciseCatalogIssue({
    required this.rowIndex,
    required this.path,
    required this.problem,
    this.exerciseId,
  });

  /// Zero-based position of the row in the decoded catalog.
  final int rowIndex;

  /// Raw `id` of the row when it could be read as a string.
  final String? exerciseId;

  /// Field path inside the row, such as `equipment.primary`.
  final String path;

  final String problem;

  @override
  bool operator ==(Object other) =>
      other is ExerciseCatalogIssue &&
      other.rowIndex == rowIndex &&
      other.exerciseId == exerciseId &&
      other.path == path &&
      other.problem == problem;

  @override
  int get hashCode => Object.hash(rowIndex, exerciseId, path, problem);

  @override
  String toString() {
    final id = exerciseId == null ? '' : ' ($exerciseId)';
    return 'row $rowIndex$id $path: $problem';
  }
}

/// Thrown when any built-in catalog row is invalid.
///
/// The bundled catalog is versioned content, so one invalid row fails the
/// whole catalog instead of silently dropping stable Exercise identities.
final class InvalidExerciseCatalogException implements Exception {
  InvalidExerciseCatalogException(Iterable<ExerciseCatalogIssue> issues)
      : issues = List<ExerciseCatalogIssue>.unmodifiable(issues);

  final List<ExerciseCatalogIssue> issues;

  @override
  String toString() =>
      'InvalidExerciseCatalogException: ${issues.length} issue(s): '
      '${issues.join('; ')}';
}

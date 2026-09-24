import 'package:tio_shared/shared.dart';

import '../../domain/exercises/invalid_exercise_catalog_exception.dart';

/// Typed view of the built-in catalog row fields W3A consumes.
///
/// Data-boundary only: presentation and other consumers see canonical
/// [Exercise] values. Unknown row keys are ignored. Presence and type are
/// checked here; value rules such as blank or duplicate taxonomy come from
/// the canonical [Exercise] contract.
final class ExerciseCatalogRowDto {
  const ExerciseCatalogRowDto._({
    required this.rowIndex,
    required this.id,
    required this.title,
    required this.muscleGroup,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.primaryEquipment,
    required this.category,
    required this.levels,
    required this.isArchived,
  });

  final int rowIndex;
  final String id;
  final String title;
  final String muscleGroup;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String primaryEquipment;
  final String category;
  final List<String> levels;
  final bool isArchived;

  /// JSON paths for canonical [Exercise] argument names that differ.
  static const _pathByArgument = {
    'displayName': 'title',
    'primaryEquipment': 'equipment.primary',
  };

  /// Reads one decoded row, or appends issues to [issues] and returns null.
  static ExerciseCatalogRowDto? read(
    Object? row,
    int rowIndex,
    List<ExerciseCatalogIssue> issues,
  ) {
    if (row is! Map) {
      issues.add(ExerciseCatalogIssue(
        rowIndex: rowIndex,
        path: r'$',
        problem: 'must be an object',
      ));
      return null;
    }

    final rawId = row['id'];
    final exerciseId = rawId is String ? rawId : null;
    final issueCount = issues.length;

    void problem(String path, String description) {
      issues.add(ExerciseCatalogIssue(
        rowIndex: rowIndex,
        exerciseId: exerciseId,
        path: path,
        problem: description,
      ));
    }

    T? field<T>(Map<dynamic, dynamic> map, String key, String path) {
      if (!map.containsKey(key)) {
        problem(path, 'is required');
        return null;
      }
      final value = map[key];
      if (value is T) return value;
      problem(path, 'must be ${_describe<T>()}');
      return null;
    }

    List<String>? stringList(String key) {
      final value = field<List<dynamic>>(row, key, key);
      if (value == null) return null;
      if (value.any((item) => item is! String)) {
        problem(key, 'must be a list of strings');
        return null;
      }
      return List<String>.from(value);
    }

    final id = field<String>(row, 'id', 'id');
    final title = field<String>(row, 'title', 'title');
    final muscleGroup = field<String>(row, 'muscleGroup', 'muscleGroup');
    final primaryMuscles = stringList('primaryMuscles');
    final secondaryMuscles = stringList('secondaryMuscles');
    final equipment =
        field<Map<dynamic, dynamic>>(row, 'equipment', 'equipment');
    final primaryEquipment = equipment == null
        ? null
        : field<String>(equipment, 'primary', 'equipment.primary');
    final category = field<String>(row, 'category', 'category');
    final levels = stringList('levels');
    final isArchived = field<bool>(row, 'isArchived', 'isArchived');
    final isCustom = field<bool>(row, 'isCustom', 'isCustom');
    if (isCustom == true) {
      problem('isCustom', 'must be false for a built-in catalog row');
    }

    if (issues.length != issueCount) return null;
    return ExerciseCatalogRowDto._(
      rowIndex: rowIndex,
      id: id!,
      title: title!,
      muscleGroup: muscleGroup!,
      primaryMuscles: primaryMuscles!,
      secondaryMuscles: secondaryMuscles!,
      primaryEquipment: primaryEquipment!,
      category: category!,
      levels: levels!,
      isArchived: isArchived!,
    );
  }

  /// Maps to canonical [Exercise], or appends an issue and returns null.
  Exercise? toExercise(List<ExerciseCatalogIssue> issues) {
    void problem(String path, String description) {
      issues.add(ExerciseCatalogIssue(
        rowIndex: rowIndex,
        exerciseId: id,
        path: path,
        problem: description,
      ));
    }

    final ExerciseRef ref;
    try {
      ref = ExerciseRef.catalog(id);
    } on ArgumentError {
      problem('id', 'must be a built-in catalog ex_* identifier');
      return null;
    }

    try {
      return Exercise(
        ref: ref,
        displayName: title,
        muscleGroup: muscleGroup,
        primaryMuscles: primaryMuscles,
        secondaryMuscles: secondaryMuscles,
        primaryEquipment: primaryEquipment,
        category: category,
        levels: levels,
        status: isArchived ? ExerciseStatus.archived : ExerciseStatus.active,
      );
    } on ArgumentError catch (error) {
      final argument = error.name ?? 'row';
      problem(
        _pathByArgument[argument] ?? argument,
        '${error.message}',
      );
      return null;
    }
  }

  static String _describe<T>() => switch (T) {
        const (String) => 'a string',
        const (bool) => 'a boolean',
        const (List<dynamic>) => 'a list',
        _ => 'an object',
      };
}

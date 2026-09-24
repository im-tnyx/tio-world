import 'package:tio_shared/shared.dart';

import 'exercise_catalog.dart';

/// Pure browse/search query over an [ExerciseCatalog].
///
/// [text] matches [Exercise.displayName] only, as a case-insensitive
/// substring after trimming and collapsing whitespace; empty text matches
/// every Exercise. Each filter is an exact, optional single-select taxonomy
/// value where `null` means any. Archived exercises are never returned, and
/// results keep the catalog's display order.
final class ExerciseCatalogQuery {
  const ExerciseCatalogQuery({
    this.text = '',
    this.muscleGroup,
    this.primaryEquipment,
    this.category,
  });

  final String text;
  final String? muscleGroup;
  final String? primaryEquipment;
  final String? category;

  static final _whitespace = RegExp(r'\s+');

  List<Exercise> apply(ExerciseCatalog catalog) {
    final needle = _normalize(text);
    return List<Exercise>.unmodifiable([
      for (final exercise in catalog.all)
        if (_matches(exercise, needle)) exercise,
    ]);
  }

  bool _matches(Exercise exercise, String needle) =>
      exercise.status == ExerciseStatus.active &&
      (muscleGroup == null || exercise.muscleGroup == muscleGroup) &&
      (primaryEquipment == null ||
          exercise.primaryEquipment == primaryEquipment) &&
      (category == null || exercise.category == category) &&
      (needle.isEmpty || _normalize(exercise.displayName).contains(needle));

  static String _normalize(String value) =>
      value.trim().replaceAll(_whitespace, ' ').toLowerCase();

  @override
  bool operator ==(Object other) =>
      other is ExerciseCatalogQuery &&
      other.text == text &&
      other.muscleGroup == muscleGroup &&
      other.primaryEquipment == primaryEquipment &&
      other.category == category;

  @override
  int get hashCode =>
      Object.hash(text, muscleGroup, primaryEquipment, category);
}

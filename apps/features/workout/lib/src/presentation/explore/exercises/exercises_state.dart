import 'package:tio_shared/shared.dart';

import '../../../domain/exercises/exercise_catalog_query.dart';

/// Load outcome of the dedicated Exercises screen.
enum ExercisesStatus {
  loading,
  ready,

  /// The bundled catalog asset is absent from this app build.
  missingCatalog,

  /// The bundled catalog exists but this app version cannot read it.
  malformedCatalog,

  /// Any other load failure.
  failed,
}

/// One single-select taxonomy filter on the Exercises screen.
enum ExerciseFilterDimension { muscle, equipment, category }

/// One selectable value of an [ExerciseFilterDimension].
final class ExerciseFilterOption {
  const ExerciseFilterOption({required this.value, required this.label});

  /// Catalog taxonomy token, such as `upper_arms`.
  final String value;

  /// Display label, such as `Upper arms`.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is ExerciseFilterOption &&
      other.value == value &&
      other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

/// Presentation data for one Exercise row.
final class ExerciseListItem {
  const ExerciseListItem({
    required this.exercise,
    required this.thumbnailUrl,
    required this.metadata,
  });

  final Exercise exercise;

  /// Image chosen by `ExerciseMedia.urlFor`; null renders a text-only row.
  final Uri? thumbnailUrl;

  /// `Primary equipment • Muscle group`, or whichever part exists.
  final String? metadata;

  String get name => exercise.displayName;

  @override
  bool operator ==(Object other) =>
      other is ExerciseListItem &&
      other.exercise == exercise &&
      other.thumbnailUrl == thumbnailUrl &&
      other.metadata == metadata;

  @override
  int get hashCode => Object.hash(exercise, thumbnailUrl, metadata);
}

/// Immutable state of the dedicated Exercises screen.
final class ExercisesState {
  const ExercisesState({
    required this.status,
    this.query = const ExerciseCatalogQuery(),
    this.items = const [],
    this.hasActiveExercises = false,
    this.filterOptions = const {},
  });

  const ExercisesState.loading() : this(status: ExercisesStatus.loading);

  final ExercisesStatus status;

  /// Current search text and filter selection.
  final ExerciseCatalogQuery query;

  /// Rows matching [query], in catalog display order.
  final List<ExerciseListItem> items;

  /// Whether the loaded catalog has any active Exercise at all.
  final bool hasActiveExercises;

  /// Selectable values per dimension, drawn from active Exercises.
  final Map<ExerciseFilterDimension, List<ExerciseFilterOption>> filterOptions;

  bool get isEmptyCatalog =>
      status == ExercisesStatus.ready && !hasActiveExercises;

  bool get isNoMatch =>
      status == ExercisesStatus.ready && hasActiveExercises && items.isEmpty;

  List<ExerciseFilterOption> optionsFor(ExerciseFilterDimension dimension) =>
      filterOptions[dimension] ?? const [];

  /// Selected taxonomy token for [dimension], or null for any.
  String? selectedValue(ExerciseFilterDimension dimension) =>
      switch (dimension) {
        ExerciseFilterDimension.muscle => query.muscleGroup,
        ExerciseFilterDimension.equipment => query.primaryEquipment,
        ExerciseFilterDimension.category => query.category,
      };

  int get activeFilterCount => ExerciseFilterDimension.values
      .where((dimension) => selectedValue(dimension) != null)
      .length;
}

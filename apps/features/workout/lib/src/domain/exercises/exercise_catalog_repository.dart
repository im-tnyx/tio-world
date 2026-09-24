import 'exercise_catalog.dart';

/// Read-only source of the built-in Exercise catalog.
///
/// [load] completes with a validated [ExerciseCatalog], or fails with
/// `InvalidExerciseCatalogException` when any catalog row is invalid.
abstract interface class ExerciseCatalogRepository {
  Future<ExerciseCatalog> load();
}

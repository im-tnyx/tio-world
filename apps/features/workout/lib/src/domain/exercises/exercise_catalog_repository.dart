import 'exercise_catalog.dart';

/// Read-only source of the built-in Exercise catalog.
///
/// [load] completes with a validated [ExerciseCatalog], or fails with
/// `InvalidExerciseCatalogException` when any catalog row is invalid.
/// Implementations backed by a source may also fail with source/document
/// errors, such as the bundled asset source's missing-asset, asset-load,
/// invalid-document and unsupported-schema-version exceptions.
abstract interface class ExerciseCatalogRepository {
  Future<ExerciseCatalog> load();
}

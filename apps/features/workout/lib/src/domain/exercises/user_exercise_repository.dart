import 'package:tio_shared/shared.dart';

/// Persistence boundary for user-owned canonical Exercises.
///
/// Built-in catalog Exercises remain bundled application content and never
/// become rows in this repository. This boundary owns only user-created UUID
/// Exercises and intentionally exposes archive rather than hard delete.
abstract interface class UserExerciseRepository {
  /// Lists user-owned Exercises.
  ///
  /// Archived rows are excluded by default because the normal Custom smart
  /// view is an active-selection surface.
  Future<List<Exercise>> list({bool includeArchived = false});

  /// Creates one active user-owned Exercise.
  ///
  /// [basedOnCatalogExercise] records immutable source lineage when the user
  /// explicitly forks a built-in catalog Exercise definition.
  Future<void> create({
    required UserCreatedExerciseRef id,
    required String displayName,
    CatalogExerciseRef? basedOnCatalogExercise,
  });

  Future<void> rename({
    required UserCreatedExerciseRef id,
    required String displayName,
  });

  /// Archives a user-owned Exercise without deleting its stable identity.
  Future<void> archive(UserCreatedExerciseRef id);
}

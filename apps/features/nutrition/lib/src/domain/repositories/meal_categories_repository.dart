import '../models/meal_categories_config.dart';

/// A write the store refused for a reason that will not change by itself.
///
/// Deliberately separate from a transport failure. A dropped connection is
/// worth retrying with the same payload; a constraint, trigger or concurrency
/// rejection means the payload is the problem — most often because another
/// device moved the configuration on while this screen still held a snapshot
/// of it. Replaying that payload can only be refused again, forever, and if it
/// ever were accepted it would erase whatever the other device wrote.
///
/// So a conflict is never offered as a retry. The caller reloads and lets the
/// reader decide what to do with the version that is actually stored.
final class MealCategoriesWriteConflict implements Exception {
  const MealCategoriesWriteConflict({required this.message, this.cause});

  final String message;

  /// The underlying failure, kept for logging rather than for display.
  final Object? cause;

  @override
  String toString() => 'MealCategoriesWriteConflict($message)';
}

/// Repository-neutral owner of the authenticated user's Meal Categories.
abstract interface class MealCategoriesRepository {
  /// Returns a validated customized config, or canonical defaults when no
  /// customization is stored.
  Future<MealCategoriesConfig> read();

  /// Stores the complete customized config after validating every invariant.
  ///
  /// Once customized state exists, ordinary upsert must reject a config that
  /// omits any retained category identity. Identity removal/reset requires a
  /// separate future contract with explicit historical-retention semantics.
  Future<void> upsert(MealCategoriesConfig config);
}

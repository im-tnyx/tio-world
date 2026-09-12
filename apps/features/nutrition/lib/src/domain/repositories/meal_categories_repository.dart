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

/// Optional local change signal implemented by canonical repositories that can
/// observe their own successful writes.
///
/// This is intentionally separate from [MealCategoriesRepository]. Read/write
/// fakes and future adapters are not forced to become reactive. Consumers that
/// need freshness may subscribe when the concrete repository supports it.
/// Each event means a write completed successfully and a fresh [read] may now
/// return a different retained configuration. Failed or rejected writes must
/// not emit an event.
abstract interface class MealCategoriesChangeSource {
  Stream<void> get changes;
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

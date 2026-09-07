import '../models/meal_categories_config.dart';

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

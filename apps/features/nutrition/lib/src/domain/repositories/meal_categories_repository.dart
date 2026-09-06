import '../models/meal_categories_config.dart';

/// Repository-neutral owner of the authenticated user's Meal Categories.
abstract interface class MealCategoriesRepository {
  /// Returns a validated customized config, or canonical defaults when no
  /// customization is stored.
  Future<MealCategoriesConfig> read();

  /// Stores the complete customized config after validating every invariant.
  Future<void> upsert(MealCategoriesConfig config);
}

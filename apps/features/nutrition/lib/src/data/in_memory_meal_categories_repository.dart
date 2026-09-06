import '../domain/models/meal_categories_config.dart';
import '../domain/repositories/meal_categories_repository.dart';

/// Deterministic non-durable Meal Categories owner for tests/local composition.
class InMemoryMealCategoriesRepository implements MealCategoriesRepository {
  MealCategoriesConfig? _customizedConfig;

  bool get hasCustomization => _customizedConfig != null;
  MealCategoriesConfig? get customizedConfig => _customizedConfig;

  @override
  Future<MealCategoriesConfig> read() async =>
      MealCategoriesConfig.resolve(_customizedConfig);

  @override
  Future<void> upsert(MealCategoriesConfig config) async {
    config.validate();
    _customizedConfig = config;
  }
}

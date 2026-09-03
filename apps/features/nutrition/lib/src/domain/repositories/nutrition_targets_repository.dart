import '../models/nutrition_targets_data.dart';

/// Canonical owner of the five core Nutrition Targets.
///
/// Additional Nutrition carries no repository surface: those values are
/// derived at display time from canonical Calories and Profile date of birth
/// and are never persisted. The reserved
/// `user_nutrition_targets.additional_nutrient_goals` column stays unused
/// until per-nutrient editing is designed as its own product slice.
abstract interface class NutritionTargetsRepository {
  Future<NutritionTargetsData?> read();

  Future<void> upsert(NutritionTargetsData targets);
}

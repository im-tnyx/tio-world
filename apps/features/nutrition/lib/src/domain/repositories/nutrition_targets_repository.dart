import '../models/nutrition_targets_data.dart';

/// Canonical owner of the five core Nutrition Targets.
///
/// Additional Nutrition carries no repository surface: its values are derived
/// at display time from each nutrient's required canonical Nutrition
/// Targets/Profile inputs and are never persisted. The reserved
/// `user_nutrition_targets.additional_nutrient_goals` column stays unused
/// until per-nutrient editing is designed as its own product slice.
abstract interface class NutritionTargetsRepository {
  Future<NutritionTargetsData?> read();

  Future<void> upsert(NutritionTargetsData targets);
}

import '../models/nutrition_targets_data.dart';
import '../models/additional_nutrient_goal.dart';

/// Canonical Nutrition Targets owner boundary.
abstract interface class NutritionTargetsRepository {
  /// Returns the authenticated user's canonical Nutrition Targets row, or null
  /// when signed out or when no row exists.
  Future<NutritionTargetsData?> read();

  /// Replaces canonical Nutrition target values for the authenticated user.
  Future<void> upsert(NutritionTargetsData targets);

  /// Merge-updates only Additional Nutrient Goals. Implementations must
  /// preserve opaque V1 fields and refuse unsupported future schemas.
  Future<void> updateAdditionalNutrientGoals(AdditionalNutrientGoalSet goals);
}

import 'package:tio_shared/shared.dart';

import '../models/nutrition_targets_data.dart';
import '../models/additional_nutrient_goal.dart';

/// Canonical Nutrition Targets owner boundary.
abstract interface class NutritionTargetsRepository {
  /// Returns the authenticated user's canonical Nutrition Targets row, or null
  /// when signed out or when no row exists.
  Future<NutritionTargetsData?> read();

  /// Replaces canonical Nutrition target values for the authenticated user.
  Future<void> upsert(NutritionTargetsData targets);

  /// Applies one nutrient's Additional Nutrient Goal change.
  ///
  /// Deliberately a single-nutrient delta, not a set replacement: a caller's
  /// goal set is a snapshot, so writing all of it would delete a nutrient
  /// another client configured after that snapshot was taken. A null [goal]
  /// removes the nutrient. Implementations must preserve every other entry,
  /// including opaque V1 fields, and refuse unsupported future schemas.
  Future<void> updateAdditionalNutrientGoal(
    NutrientId nutrientId,
    AdditionalNutrientGoal? goal,
  );
}

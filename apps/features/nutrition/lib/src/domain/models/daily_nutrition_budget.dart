import 'package:tio_shared/shared.dart';

import 'nutrition_targets_data.dart';

/// Derived Nutrition target truth for one explicit local calendar date.
///
/// This is a read model, not a persistence owner. [baseTarget] remains the
/// canonical Nutrition Targets truth. [strategyAdjustedTarget] is the
/// date-specific target after Nutrition Schedule rules; the Standard strategy
/// used by the N11A foundation leaves it unchanged.
final class DailyNutritionBudget {
  const DailyNutritionBudget({
    required this.localDate,
    required this.baseTarget,
    required this.strategyAdjustedTarget,
  });

  final MealLogLocalDate localDate;
  final NutritionTargetsData baseTarget;
  final NutritionTargetsData strategyAdjustedTarget;
}

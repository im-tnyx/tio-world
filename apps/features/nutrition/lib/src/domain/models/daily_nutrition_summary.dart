import 'dart:collection';

import 'package:tio_shared/shared.dart';

import 'daily_nutrition_budget.dart';

/// Derived selected-day Nutrition truth for Daily Summary and calendar progress.
///
/// This is a read model, not persisted state. Unknown values remain absent in
/// [consumedTotals] and/or the nullable [budget]; they are never replaced with
/// display zeros.
final class DailyNutritionSummary {
  DailyNutritionSummary({
    required this.localDate,
    required this.budget,
    required Map<NutrientId, num> consumedTotals,
  }) : consumedTotals = UnmodifiableMapView(
          Map<NutrientId, num>.from(consumedTotals),
        );

  final MealLogLocalDate localDate;
  final DailyNutritionBudget? budget;
  final Map<NutrientId, num> consumedTotals;

  num? consumedAmountFor(NutrientId nutrient) => consumedTotals[nutrient];

  /// Calorie target after the selected-date Nutrition strategy adjustment.
  num? get targetCaloriesKcal =>
      budget?.strategyAdjustedTarget.caloriesKcal;

  num? get eatenCaloriesKcal => consumedAmountFor(NutrientId.energy);

  /// Signed base remaining calories for workout-OFF N3A.
  ///
  /// Negative means the selected day is over its strategy-adjusted target.
  num? get remainingCaloriesKcal {
    final target = targetCaloriesKcal;
    final eaten = eatenCaloriesKcal;
    if (target == null || eaten == null) return null;
    return target - eaten;
  }

  bool get isOverCalorieTarget {
    final remaining = remainingCaloriesKcal;
    return remaining != null && remaining < 0;
  }

  /// Primary calendar progress, normalized only for rendering.
  ///
  /// The raw eaten/target facts remain available above, so clamping the ring at
  /// 100% does not erase an over-target state.
  double? get calorieProgress {
    final target = targetCaloriesKcal;
    final eaten = eatenCaloriesKcal;
    if (target == null || eaten == null || target <= 0) return null;
    return (eaten / target).clamp(0, 1).toDouble();
  }

  /// Target for the N3A nutrient rows.
  ///
  /// Energy uses the strategy-adjusted target. Macro/fiber rows intentionally
  /// use the canonical base target until a later approved strategy explicitly
  /// owns macro/fiber adjustment semantics.
  num? targetAmountFor(NutrientId nutrient) {
    final currentBudget = budget;
    if (currentBudget == null) return null;

    return switch (nutrient) {
      NutrientId.energy =>
        currentBudget.strategyAdjustedTarget.caloriesKcal,
      NutrientId.protein => currentBudget.baseTarget.proteinGrams,
      NutrientId.carbohydrate => currentBudget.baseTarget.carbohydrateGrams,
      NutrientId.fat => currentBudget.baseTarget.fatGrams,
      NutrientId.fiber => currentBudget.baseTarget.fiberGrams,
      _ => null,
    };
  }

  /// Normalized bar progress when both consumed and positive target truth exist.
  double? progressFor(NutrientId nutrient) {
    final target = targetAmountFor(nutrient);
    final consumed = consumedAmountFor(nutrient);
    if (target == null || consumed == null || target <= 0) return null;
    return (consumed / target).clamp(0, 1).toDouble();
  }
}

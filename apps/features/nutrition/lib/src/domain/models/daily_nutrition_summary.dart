import 'dart:collection';

import 'package:tio_shared/shared.dart';

import 'daily_nutrition_budget.dart';

/// Derived selected-day Nutrition truth for Daily Summary and calendar progress.
///
/// This is a read model, not persisted state. Unknown exact values remain absent
/// in [consumedTotals] and/or the nullable [budget]; they are never replaced
/// with display zeros. When a nutrient is only partially known,
/// [confirmedConsumedTotals] may carry a presentation-safe lower bound while
/// [missingConsumedEntryCounts] proves that the exact total is unavailable.
final class DailyNutritionSummary {
  DailyNutritionSummary({
    required this.localDate,
    required this.budget,
    required Map<NutrientId, num> consumedTotals,
    Map<NutrientId, num> confirmedConsumedTotals = const {},
    Map<NutrientId, int> missingConsumedEntryCounts = const {},
  })  : consumedTotals = UnmodifiableMapView(
          Map<NutrientId, num>.from(consumedTotals),
        ),
        confirmedConsumedTotals = UnmodifiableMapView(
          Map<NutrientId, num>.from(confirmedConsumedTotals),
        ),
        missingConsumedEntryCounts = UnmodifiableMapView(
          Map<NutrientId, int>.from(missingConsumedEntryCounts),
        );

  final MealLogLocalDate localDate;
  final DailyNutritionBudget? budget;

  /// Exact consumed totals only.
  ///
  /// A nutrient is absent when at least one contributing MealLog is missing
  /// that fact. This contract remains the only input to exact progress math.
  final Map<NutrientId, num> consumedTotals;

  /// Confirmed lower bounds for incomplete nutrients.
  ///
  /// Entries are present only when at least one contributing MealLog contains
  /// the nutrient while another entry is missing it. These values are safe to
  /// present with a `+` suffix but must never be treated as exact totals.
  final Map<NutrientId, num> confirmedConsumedTotals;

  /// Number of contributing MealLogs missing each nutrient fact.
  final Map<NutrientId, int> missingConsumedEntryCounts;

  num? consumedAmountFor(NutrientId nutrient) => consumedTotals[nutrient];

  /// Returns exact consumed truth when available, otherwise a confirmed lower
  /// bound for an incomplete nutrient.
  num? confirmedConsumedAmountFor(NutrientId nutrient) =>
      consumedTotals[nutrient] ?? confirmedConsumedTotals[nutrient];

  int missingConsumedEntryCountFor(NutrientId nutrient) =>
      missingConsumedEntryCounts[nutrient] ?? 0;

  bool isConsumedIncompleteFor(NutrientId nutrient) =>
      consumedTotals[nutrient] == null &&
      missingConsumedEntryCountFor(nutrient) > 0;

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
  /// 100% does not erase an over-target state. Incomplete calorie lower bounds
  /// deliberately do not drive this exact progress contract.
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

  /// Normalized bar progress when both exact consumed and positive target truth
  /// exist. A confirmed lower bound is intentionally insufficient.
  double? progressFor(NutrientId nutrient) {
    final target = targetAmountFor(nutrient);
    final consumed = consumedAmountFor(nutrient);
    if (target == null || consumed == null || target <= 0) return null;
    return (consumed / target).clamp(0, 1).toDouble();
  }
}

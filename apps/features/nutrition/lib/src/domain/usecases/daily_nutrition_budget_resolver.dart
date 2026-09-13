import 'package:tio_shared/shared.dart';

import '../models/daily_nutrition_budget.dart';
import '../repositories/nutrition_targets_repository.dart';

/// Resolves derived Nutrition target truth for an explicit local date.
///
/// N11A supports only the Standard strategy, so the strategy-adjusted target
/// is the canonical base target unchanged. Later Nutrition Schedule rules can
/// be inserted here without moving target ownership or asking consumers to
/// interpret persistence directly.
final class DailyNutritionBudgetResolver {
  const DailyNutritionBudgetResolver({
    required NutritionTargetsRepository nutritionTargetsRepository,
  }) : _nutritionTargetsRepository = nutritionTargetsRepository;

  final NutritionTargetsRepository _nutritionTargetsRepository;

  /// Returns `null` only when no canonical Nutrition Targets row exists.
  ///
  /// Repository failures remain failures. Nullable nutrient fields inside a
  /// present target remain unknown/unset and are never fabricated as zero.
  Future<DailyNutritionBudget?> resolve(MealLogLocalDate localDate) async {
    final baseTarget = await _nutritionTargetsRepository.read();
    if (baseTarget == null) return null;

    baseTarget.validate();
    return DailyNutritionBudget(
      localDate: localDate,
      baseTarget: baseTarget,
      strategyAdjustedTarget: baseTarget,
    );
  }
}

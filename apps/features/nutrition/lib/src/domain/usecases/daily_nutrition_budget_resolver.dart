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

  /// Returns `null` when canonical Nutrition Targets are unavailable under the
  /// repository's existing read contract.
  ///
  /// The canonical Supabase repository deliberately uses `null` for both a
  /// missing target row and a signed-out/no-authenticated-read context. This
  /// resolver must not infer or create authentication state from that value.
  /// Repository exceptions still remain failures. Nullable nutrient fields
  /// inside a present target remain unknown/unset and are never fabricated as
  /// zero.
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

import 'package:tio_shared/shared.dart';

import '../models/daily_nutrition_budget.dart';
import '../models/nutrition_targets_data.dart';
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
    final baseTarget = await _readValidatedBaseTarget();
    return _resolveWithBaseTarget(localDate, baseTarget);
  }

  /// Resolves several explicit dates from one canonical target read.
  ///
  /// Calendar consumers use this instead of issuing one identical target read
  /// per visible date. Each requested date remains explicit in the returned
  /// map so later N11 schedule rules can vary strategy adjustment by date
  /// without changing the consumer contract.
  Future<Map<MealLogLocalDate, DailyNutritionBudget?>> resolveMany(
    Iterable<MealLogLocalDate> localDates,
  ) async {
    final dates = <MealLogLocalDate>{...localDates};
    if (dates.isEmpty) {
      return const <MealLogLocalDate, DailyNutritionBudget?>{};
    }

    final baseTarget = await _readValidatedBaseTarget();
    return Map<MealLogLocalDate, DailyNutritionBudget?>.unmodifiable({
      for (final date in dates) date: _resolveWithBaseTarget(date, baseTarget),
    });
  }

  Future<NutritionTargetsData?> _readValidatedBaseTarget() async {
    final baseTarget = await _nutritionTargetsRepository.read();
    baseTarget?.validate();
    return baseTarget;
  }

  static DailyNutritionBudget? _resolveWithBaseTarget(
    MealLogLocalDate localDate,
    NutritionTargetsData? baseTarget,
  ) {
    if (baseTarget == null) return null;
    return DailyNutritionBudget(
      localDate: localDate,
      baseTarget: baseTarget,
      strategyAdjustedTarget: baseTarget,
    );
  }
}

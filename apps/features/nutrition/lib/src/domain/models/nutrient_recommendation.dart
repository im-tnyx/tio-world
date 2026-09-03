import 'package:tio_shared/shared.dart';

import 'nutrient_goal_semantics.dart';

/// A runtime-derived Additional Nutrition reference value.
///
/// Never serialized. Additional Nutrition is a read-only calculated surface in
/// V1, so there is no stored counterpart to reconcile against: every value on
/// screen is derived from canonical Nutrition Targets and Profile inputs at
/// display time.
///
/// [recommendedValue] is null when the rule's canonical inputs are missing or
/// the user is outside the rule's population. That is rendered as Unavailable
/// rather than defaulted, because inventing a nutrition figure is worse than
/// admitting the app cannot derive one.
final class NutrientRecommendation {
  const NutrientRecommendation._({
    required this.nutrientId,
    required this.goalType,
    required this.comparison,
    required this.recommendedValue,
  });

  const NutrientRecommendation.available({
    required NutrientId nutrientId,
    required NutrientGoalType goalType,
    required NutrientGoalComparison comparison,
    required double recommendedValue,
  }) : this._(
          nutrientId: nutrientId,
          goalType: goalType,
          comparison: comparison,
          recommendedValue: recommendedValue,
        );

  const NutrientRecommendation.unavailable({
    required NutrientId nutrientId,
    required NutrientGoalType goalType,
    required NutrientGoalComparison comparison,
  }) : this._(
          nutrientId: nutrientId,
          goalType: goalType,
          comparison: comparison,
          recommendedValue: null,
        );

  final NutrientId nutrientId;
  final NutrientGoalType goalType;
  final NutrientGoalComparison comparison;
  final double? recommendedValue;

  bool get isAvailable => recommendedValue != null;
}

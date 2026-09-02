import 'package:tio_shared/shared.dart';

import 'additional_nutrient_goal.dart';

/// Runtime-only recommendation. It is never serialized into target storage.
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

  double? effectiveValueFor(AdditionalNutrientGoal? goal) =>
      goal?.customValue ?? recommendedValue;
}

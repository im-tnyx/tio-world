import 'package:tio_shared/shared.dart';

import '../models/additional_nutrient_goal.dart';
import '../models/nutrient_recommendation.dart';

/// Frozen TNYX-141 V1 policy for the four authorized nutrients.
final class AdditionalNutrientRecommendationPolicy {
  const AdditionalNutrientRecommendationPolicy._();

  static NutrientRecommendation derive({
    required NutrientId nutrientId,
    required int? caloriesKcal,
    required DateTime? dateOfBirth,
    required DateTime now,
  }) {
    final definition = _definitionFor(nutrientId);
    final age = ageOn(dateOfBirth: dateOfBirth, now: now);

    // The frozen V1 population is adults only. A missing/invalid DOB and an
    // age below 19 are unavailable rather than guessed.
    if (age == null || age < 19) return definition.unavailable(nutrientId);

    final value = switch (nutrientId) {
      NutrientId.saturatedFat =>
        caloriesKcal == null ? null : (0.10 * caloriesKcal) / 9,
      NutrientId.transFat =>
        caloriesKcal == null ? null : (0.01 * caloriesKcal) / 9,
      NutrientId.sodium => 2000.0,
      NutrientId.vitaminD => age <= 70 ? 15.0 : 20.0,
      _ => throw ArgumentError.value(
          nutrientId,
          'nutrientId',
          'Nutrient is outside Additional Nutrient Goals V1.',
        ),
    };

    return value == null
        ? definition.unavailable(nutrientId)
        : definition.available(nutrientId, value);
  }

  /// Age on [now]'s calendar date. Leap-day birthdays turn a year older on
  /// March 1 in non-leap years because February 29 has not occurred.
  static int? ageOn({required DateTime? dateOfBirth, required DateTime now}) {
    if (dateOfBirth == null || dateOfBirth.isAfter(now)) return null;
    var age = now.year - dateOfBirth.year;
    final birthdayOccurred = now.month > dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day >= dateOfBirth.day);
    if (!birthdayOccurred) age--;
    return age;
  }

  static _PolicyDefinition _definitionFor(NutrientId nutrientId) {
    return switch (nutrientId) {
      NutrientId.saturatedFat => const _PolicyDefinition(
          NutrientGoalType.maximum,
          NutrientGoalComparison.atMost,
        ),
      NutrientId.transFat => const _PolicyDefinition(
          NutrientGoalType.maximum,
          NutrientGoalComparison.atMost,
        ),
      NutrientId.sodium => const _PolicyDefinition(
          NutrientGoalType.maximum,
          NutrientGoalComparison.lessThan,
        ),
      NutrientId.vitaminD => const _PolicyDefinition(
          NutrientGoalType.target,
          NutrientGoalComparison.target,
        ),
      _ => throw ArgumentError.value(
          nutrientId,
          'nutrientId',
          'Nutrient is outside Additional Nutrient Goals V1.',
        ),
    };
  }
}

final class _PolicyDefinition {
  const _PolicyDefinition(this.goalType, this.comparison);

  final NutrientGoalType goalType;
  final NutrientGoalComparison comparison;

  NutrientRecommendation available(NutrientId nutrientId, double value) =>
      NutrientRecommendation.available(
        nutrientId: nutrientId,
        goalType: goalType,
        comparison: comparison,
        recommendedValue: value,
      );

  NutrientRecommendation unavailable(NutrientId nutrientId) =>
      NutrientRecommendation.unavailable(
        nutrientId: nutrientId,
        goalType: goalType,
        comparison: comparison,
      );
}


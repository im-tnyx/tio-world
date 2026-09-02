import 'package:tio_shared/shared.dart';

import '../models/additional_nutrient_goal.dart';
import '../models/nutrient_recommendation.dart';

/// Why a recommendation could not be derived.
///
/// Which of these can apply depends on the nutrient: every V1 nutrient needs
/// adult eligibility, but only the calorie-percentage rules need a Calories
/// target. Callers use this to explain the actual blocker instead of listing
/// inputs the nutrient does not use.
enum NutrientRecommendationBlocker {
  /// No usable date of birth, so eligibility cannot be established.
  dateOfBirthMissing,

  /// Known age, but below the adults-only V1 population.
  ageBelowMinimum,

  /// A calorie-derived nutrient with no canonical Calories target.
  caloriesMissing,
}

/// Frozen TNYX-141 V1 policy for the four authorized nutrients.
final class AdditionalNutrientRecommendationPolicy {
  const AdditionalNutrientRecommendationPolicy._();

  /// Minimum age for every V1 recommendation. There is no pediatric policy.
  static const minimumAge = 19;

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
    if (age == null || age < minimumAge) {
      return definition.unavailable(nutrientId);
    }

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

  /// The unmet prerequisites for [nutrientId], in the order worth reporting.
  ///
  /// Empty when the recommendation is derivable. Only inputs this nutrient
  /// actually uses are ever reported: telling a Vitamin D user to set a
  /// Calories target would name an input its rule never reads.
  static Set<NutrientRecommendationBlocker> blockersFor({
    required NutrientId nutrientId,
    required int? caloriesKcal,
    required DateTime? dateOfBirth,
    required DateTime now,
  }) {
    final blockers = <NutrientRecommendationBlocker>{};
    final age = ageOn(dateOfBirth: dateOfBirth, now: now);

    if (age == null) {
      blockers.add(NutrientRecommendationBlocker.dateOfBirthMissing);
    } else if (age < minimumAge) {
      blockers.add(NutrientRecommendationBlocker.ageBelowMinimum);
    }

    if (dependsOnCalories(nutrientId) && caloriesKcal == null) {
      blockers.add(NutrientRecommendationBlocker.caloriesMissing);
    }

    return blockers;
  }

  /// Whether the nutrient's rule reads the canonical Calories target.
  ///
  /// Only the two percentage-of-energy rules do. Sodium and Vitamin D are
  /// fixed amounts gated on age alone.
  static bool dependsOnCalories(NutrientId nutrientId) =>
      nutrientId == NutrientId.saturatedFat ||
      nutrientId == NutrientId.transFat;

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

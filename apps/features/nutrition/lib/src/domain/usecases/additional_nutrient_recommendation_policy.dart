import 'package:tio_shared/shared.dart';

import '../models/nutrient_goal_semantics.dart';
import '../models/nutrient_recommendation.dart';

/// Why a recommendation could not be derived.
///
/// Which of these can apply depends on the nutrient. Callers use this to name
/// the input that would actually unblock the value, instead of listing every
/// input the policy knows about.
enum NutrientRecommendationBlocker {
  /// No usable date of birth, so eligibility and age bands cannot be resolved.
  dateOfBirthMissing,

  /// Known age, but below the adults-only V1 population.
  ageBelowMinimum,

  /// A calorie-derived nutrient with no canonical Calories target.
  caloriesMissing,

  /// The rule needs a canonical health reference sex that Tio does not yet
  /// own. Deliberately distinct from a missing date of birth: the user has
  /// supplied everything they currently can, and the gap is ours.
  referenceSexUnavailable,
}

/// Frozen TNYX-141 V1 policy for the seven Additional Nutrition values.
///
/// Every value here is calculated from canonical Nutrition Targets and Profile
/// inputs at display time and is never persisted. Additional Nutrition is a
/// read-only reference surface in V1; per-nutrient editing and custom
/// overrides are a separate, later product slice.
final class AdditionalNutrientRecommendationPolicy {
  const AdditionalNutrientRecommendationPolicy._();

  /// Minimum age for the four age-dependent V1 recommendations.
  ///
  /// The three percentage-of-energy rules depend on canonical Calories only
  /// and deliberately do not inherit this eligibility gate.
  static const minimumAge = 19;

  /// Display order, following nutrition-label convention: fats, then the
  /// carbohydrate-derived value, then minerals, then vitamins. Deterministic
  /// and independent of the enum's declaration order.
  static const displayOrder = <NutrientId>[
    NutrientId.saturatedFat,
    NutrientId.transFat,
    NutrientId.addedSugar,
    NutrientId.sodium,
    NutrientId.calcium,
    NutrientId.phosphorus,
    NutrientId.vitaminD,
  ];

  static NutrientRecommendation derive({
    required NutrientId nutrientId,
    required int? caloriesKcal,
    required DateTime? dateOfBirth,
    required DateTime now,
  }) {
    final definition = _definitionFor(nutrientId);
    final age = ageOn(dateOfBirth: dateOfBirth, now: now);

    // Only age-dependent rules are adult-gated. Coupling the percentage rules
    // to DOB would hide valid Calories-derived values for no policy reason.
    if (requiresAdultEligibility(nutrientId) &&
        (age == null || age < minimumAge)) {
      return definition.unavailable(nutrientId);
    }

    final value = switch (nutrientId) {
      // Percentage-of-energy rules. 9 kcal/g for fat, 4 kcal/g for sugar.
      NutrientId.saturatedFat =>
        caloriesKcal == null ? null : (0.10 * caloriesKcal) / 9,
      NutrientId.transFat =>
        caloriesKcal == null ? null : (0.01 * caloriesKcal) / 9,
      NutrientId.addedSugar =>
        caloriesKcal == null ? null : (0.10 * caloriesKcal) / 4,

      // Fixed adult amounts, independent of Calories.
      NutrientId.sodium => 2000.0,
      NutrientId.phosphorus => 700.0,
      NutrientId.vitaminD => age! <= 70 ? 15.0 : 20.0,

      // Calcium's 51-70 band differs by health reference sex, which Tio does
      // not yet own as canonical truth (TNYX-142). Identity gender is not a
      // substitute, so that band stays Unavailable rather than guessed.
      NutrientId.calcium => switch (age!) {
          <= 50 => 1000.0,
          >= 71 => 1200.0,
          _ => null,
        },
      _ => throw ArgumentError.value(
          nutrientId,
          'nutrientId',
          'Nutrient is outside Additional Nutrition V1.',
        ),
    };

    return value == null
        ? definition.unavailable(nutrientId)
        : definition.available(nutrientId, value);
  }

  /// The unmet prerequisites for [nutrientId], in the order worth reporting.
  ///
  /// Empty when the value is derivable. Only inputs this nutrient actually
  /// uses are ever reported: telling a Vitamin D user to set a Calories target
  /// would name an input its rule never reads.
  static Set<NutrientRecommendationBlocker> blockersFor({
    required NutrientId nutrientId,
    required int? caloriesKcal,
    required DateTime? dateOfBirth,
    required DateTime now,
  }) {
    final blockers = <NutrientRecommendationBlocker>{};
    final age = ageOn(dateOfBirth: dateOfBirth, now: now);

    if (requiresAdultEligibility(nutrientId)) {
      if (age == null) {
        blockers.add(NutrientRecommendationBlocker.dateOfBirthMissing);
      } else if (age < minimumAge) {
        blockers.add(NutrientRecommendationBlocker.ageBelowMinimum);
      }
    }

    if (dependsOnCalories(nutrientId) && caloriesKcal == null) {
      blockers.add(NutrientRecommendationBlocker.caloriesMissing);
    }

    if (nutrientId == NutrientId.calcium &&
        age != null &&
        age >= 51 &&
        age <= 70) {
      blockers.add(NutrientRecommendationBlocker.referenceSexUnavailable);
    }

    return blockers;
  }

  /// Whether the nutrient's rule reads the canonical Calories target.
  ///
  /// Only the three percentage-of-energy rules do. Sodium, calcium,
  /// phosphorus and vitamin D are fixed amounts banded by age alone.
  static bool dependsOnCalories(NutrientId nutrientId) =>
      nutrientId == NutrientId.saturatedFat ||
      nutrientId == NutrientId.transFat ||
      nutrientId == NutrientId.addedSugar;

  /// Whether the nutrient needs a valid DOB-derived adult age.
  ///
  /// Kept explicit so a new Calories-derived rule cannot accidentally inherit
  /// the eligibility requirements of the age-banded nutrients.
  static bool requiresAdultEligibility(NutrientId nutrientId) =>
      nutrientId == NutrientId.sodium ||
      nutrientId == NutrientId.calcium ||
      nutrientId == NutrientId.phosphorus ||
      nutrientId == NutrientId.vitaminD;

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
      // Added sugar is "less than 10% of Calories", a strict boundary like
      // sodium rather than an inclusive ceiling.
      NutrientId.addedSugar => const _PolicyDefinition(
          NutrientGoalType.maximum,
          NutrientGoalComparison.lessThan,
        ),
      NutrientId.sodium => const _PolicyDefinition(
          NutrientGoalType.maximum,
          NutrientGoalComparison.lessThan,
        ),
      NutrientId.calcium => const _PolicyDefinition(
          NutrientGoalType.target,
          NutrientGoalComparison.target,
        ),
      NutrientId.phosphorus => const _PolicyDefinition(
          NutrientGoalType.target,
          NutrientGoalComparison.target,
        ),
      NutrientId.vitaminD => const _PolicyDefinition(
          NutrientGoalType.target,
          NutrientGoalComparison.target,
        ),
      _ => throw ArgumentError.value(
          nutrientId,
          'nutrientId',
          'Nutrient is outside Additional Nutrition V1.',
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

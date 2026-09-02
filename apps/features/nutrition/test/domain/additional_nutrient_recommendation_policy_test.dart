import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// Frozen TNYX-141 V1 recommendation policy.
///
/// These are the owner-approved contracts, not derived preferences: the
/// percentage formulas, the strict sodium boundary, the adults-only
/// eligibility rule, and the Vitamin D age split. Recommendations are runtime
/// derivations, so every unavailable case must stay explicitly unavailable
/// rather than falling back to a fabricated number.
void main() {
  // A fixed "today" keeps age assertions deterministic.
  final now = DateTime(2026, 9, 2);

  DateTime dobForAge(int age, {int monthOffset = 0, int dayOffset = 0}) =>
      DateTime(now.year - age, now.month + monthOffset, now.day + dayOffset);

  NutrientRecommendation derive(
    NutrientId nutrientId, {
    int? caloriesKcal = 2000,
    DateTime? dateOfBirth,
  }) =>
      AdditionalNutrientRecommendationPolicy.derive(
        nutrientId: nutrientId,
        caloriesKcal: caloriesKcal,
        dateOfBirth: dateOfBirth ?? dobForAge(30),
        now: now,
      );

  group('saturated fat', () {
    test('is 10% of calories converted at 9 kcal per gram', () {
      for (final calories in [1200, 1800, 2000, 2450, 3100]) {
        final recommendation = derive(
          NutrientId.saturatedFat,
          caloriesKcal: calories,
        );

        expect(
          recommendation.recommendedValue,
          closeTo((0.10 * calories) / 9, 1e-9),
          reason: '$calories kcal',
        );
      }
    });

    test('does not round the derived value', () {
      // 2000 kcal -> 22.222... g. A rounded implementation would return 22.2
      // or 22, so assert the full precision the domain must preserve.
      final recommendation = derive(
        NutrientId.saturatedFat,
        caloriesKcal: 2000,
      );

      expect(recommendation.recommendedValue, closeTo(22.2222222222, 1e-9));
      expect(recommendation.recommendedValue, isNot(22.2));
      expect(recommendation.recommendedValue, isNot(22.0));
    });

    test('is a maximum compared at most', () {
      final recommendation = derive(NutrientId.saturatedFat);

      expect(recommendation.goalType, NutrientGoalType.maximum);
      expect(recommendation.comparison, NutrientGoalComparison.atMost);
    });

    test('is unavailable when canonical Calories is unavailable', () {
      final recommendation = derive(
        NutrientId.saturatedFat,
        caloriesKcal: null,
      );

      expect(recommendation.isAvailable, isFalse);
      expect(recommendation.recommendedValue, isNull);
    });
  });

  group('trans fat', () {
    test('is 1% of calories converted at 9 kcal per gram', () {
      for (final calories in [1200, 1800, 2000, 2450, 3100]) {
        final recommendation = derive(
          NutrientId.transFat,
          caloriesKcal: calories,
        );

        expect(
          recommendation.recommendedValue,
          closeTo((0.01 * calories) / 9, 1e-9),
          reason: '$calories kcal',
        );
      }
    });

    test('does not round the derived value', () {
      final recommendation = derive(NutrientId.transFat, caloriesKcal: 2000);

      expect(recommendation.recommendedValue, closeTo(2.2222222222, 1e-9));
      expect(recommendation.recommendedValue, isNot(2.2));
      expect(recommendation.recommendedValue, isNot(2.0));
    });

    test('is a maximum compared at most', () {
      final recommendation = derive(NutrientId.transFat);

      expect(recommendation.goalType, NutrientGoalType.maximum);
      expect(recommendation.comparison, NutrientGoalComparison.atMost);
    });

    test('is unavailable when canonical Calories is unavailable', () {
      final recommendation = derive(NutrientId.transFat, caloriesKcal: null);

      expect(recommendation.isAvailable, isFalse);
    });
  });

  group('sodium', () {
    test('is 2000 mg for an eligible adult', () {
      final recommendation = derive(
        NutrientId.sodium,
        dateOfBirth: dobForAge(19),
      );

      expect(recommendation.recommendedValue, 2000);
    });

    test('is a strict less-than boundary, not an inclusive maximum', () {
      final recommendation = derive(NutrientId.sodium);

      expect(recommendation.goalType, NutrientGoalType.maximum);
      expect(
        recommendation.comparison,
        NutrientGoalComparison.lessThan,
        reason: 'Sodium is "less than 2,000 mg/day", never "at most".',
      );
      expect(recommendation.comparison, isNot(NutrientGoalComparison.atMost));
    });

    test('does not depend on Calories', () {
      final recommendation = derive(NutrientId.sodium, caloriesKcal: null);

      expect(recommendation.recommendedValue, 2000);
    });

    test('is unavailable under 19 with no child formula substituted', () {
      for (final age in [0, 5, 12, 18]) {
        final recommendation = derive(
          NutrientId.sodium,
          dateOfBirth: dobForAge(age),
        );

        expect(recommendation.isAvailable, isFalse, reason: 'age $age');
        expect(recommendation.recommendedValue, isNull, reason: 'age $age');
      }
    });
  });

  group('vitamin D', () {
    test('is 15 mcg from 19 through 70', () {
      for (final age in [19, 20, 45, 69, 70]) {
        final recommendation = derive(
          NutrientId.vitaminD,
          dateOfBirth: dobForAge(age),
        );

        expect(recommendation.recommendedValue, 15, reason: 'age $age');
      }
    });

    test('is 20 mcg from 71 onward', () {
      for (final age in [71, 72, 90]) {
        final recommendation = derive(
          NutrientId.vitaminD,
          dateOfBirth: dobForAge(age),
        );

        expect(recommendation.recommendedValue, 20, reason: 'age $age');
      }
    });

    test('switches exactly on the 71st birthday, not the calendar year', () {
      // The day before the 71st birthday the user is still 70.
      final dayBefore = derive(
        NutrientId.vitaminD,
        dateOfBirth: DateTime(now.year - 71, now.month, now.day + 1),
      );
      expect(dayBefore.recommendedValue, 15);

      // On the birthday itself they are 71.
      final onBirthday = derive(
        NutrientId.vitaminD,
        dateOfBirth: DateTime(now.year - 71, now.month, now.day),
      );
      expect(onBirthday.recommendedValue, 20);

      // A naive year subtraction would already report 71 here; a correct
      // current-date calculation must still report 70.
      final laterThisYear = derive(
        NutrientId.vitaminD,
        dateOfBirth: DateTime(now.year - 71, now.month + 1, now.day),
      );
      expect(
        laterThisYear.recommendedValue,
        15,
        reason: 'Birthday has not occurred yet this year.',
      );
    });

    test('is a target goal', () {
      final recommendation = derive(NutrientId.vitaminD);

      expect(recommendation.goalType, NutrientGoalType.target);
      expect(recommendation.comparison, NutrientGoalComparison.target);
    });

    test('does not depend on Calories', () {
      final recommendation = derive(NutrientId.vitaminD, caloriesKcal: null);

      expect(recommendation.recommendedValue, 15);
    });

    test('is unavailable under 19', () {
      final recommendation = derive(
        NutrientId.vitaminD,
        dateOfBirth: dobForAge(18),
      );

      expect(recommendation.isAvailable, isFalse);
    });
  });

  group('missing date of birth', () {
    test('makes every age-eligible nutrient unavailable', () {
      for (final nutrientId in [NutrientId.sodium, NutrientId.vitaminD]) {
        final recommendation = AdditionalNutrientRecommendationPolicy.derive(
          nutrientId: nutrientId,
          caloriesKcal: 2000,
          dateOfBirth: null,
          now: now,
        );

        expect(recommendation.isAvailable, isFalse, reason: '$nutrientId');
      }
    });

    test('also blocks the calorie-derived nutrients, which are adults-only',
        () {
      for (final nutrientId in [
        NutrientId.saturatedFat,
        NutrientId.transFat,
      ]) {
        final recommendation = AdditionalNutrientRecommendationPolicy.derive(
          nutrientId: nutrientId,
          caloriesKcal: 2000,
          dateOfBirth: null,
          now: now,
        );

        expect(recommendation.isAvailable, isFalse, reason: '$nutrientId');
      }
    });

    test('treats a future date of birth as unusable rather than negative age',
        () {
      final recommendation = AdditionalNutrientRecommendationPolicy.derive(
        nutrientId: NutrientId.vitaminD,
        caloriesKcal: 2000,
        dateOfBirth: DateTime(now.year + 1),
        now: now,
      );

      expect(recommendation.isAvailable, isFalse);
    });
  });

  group('age calculation', () {
    test('uses the actual current date, not year subtraction', () {
      // Born late in the year: on 2026-09-02 a 2000-12-31 birth is 25, not 26.
      expect(
        AdditionalNutrientRecommendationPolicy.ageOn(
          dateOfBirth: DateTime(2000, 12, 31),
          now: now,
        ),
        25,
      );
      // Born earlier in the year: already 26.
      expect(
        AdditionalNutrientRecommendationPolicy.ageOn(
          dateOfBirth: DateTime(2000, 1, 1),
          now: now,
        ),
        26,
      );
    });

    test('counts the birthday itself as the new age', () {
      expect(
        AdditionalNutrientRecommendationPolicy.ageOn(
          dateOfBirth: DateTime(2000, 9, 2),
          now: now,
        ),
        26,
      );
      expect(
        AdditionalNutrientRecommendationPolicy.ageOn(
          dateOfBirth: DateTime(2000, 9, 3),
          now: now,
        ),
        25,
      );
    });

    test('returns null for a missing or future date of birth', () {
      expect(
        AdditionalNutrientRecommendationPolicy.ageOn(
          dateOfBirth: null,
          now: now,
        ),
        isNull,
      );
      expect(
        AdditionalNutrientRecommendationPolicy.ageOn(
          dateOfBirth: DateTime(now.year + 1),
          now: now,
        ),
        isNull,
      );
    });

    test('advances a leap-day birthday on March 1 in a non-leap year', () {
      // 2027 is not a leap year, so February 29 never occurs.
      final beforeMarch = AdditionalNutrientRecommendationPolicy.ageOn(
        dateOfBirth: DateTime(2000, 2, 29),
        now: DateTime(2027, 2, 28),
      );
      final onMarchFirst = AdditionalNutrientRecommendationPolicy.ageOn(
        dateOfBirth: DateTime(2000, 2, 29),
        now: DateTime(2027, 3, 1),
      );

      expect(beforeMarch, 26);
      expect(onMarchFirst, 27);
    });
  });

  test('rejects nutrients outside the authorized V1 subset', () {
    for (final nutrientId in [
      NutrientId.energy,
      NutrientId.protein,
      NutrientId.carbohydrate,
      NutrientId.fat,
      NutrientId.fiber,
    ]) {
      expect(
        () => derive(nutrientId),
        throwsArgumentError,
        reason: '$nutrientId is not part of Additional Nutrient Goals V1',
      );
    }
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

/// Frozen TNYX-141 V1 calculation policy for the seven Additional Nutrition
/// values.
///
/// These values are derived at display time and never persisted. Where a
/// canonical input is missing, or the population is outside the rule, the
/// policy returns unavailable rather than inventing a nutrition figure.
void main() {
  final now = DateTime(2026, 9, 3);

  DateTime dobForAge(int age) => DateTime(now.year - age, 1, 1);

  NutrientRecommendation derive(
    NutrientId nutrientId, {
    int? caloriesKcal = 2000,
    DateTime? dateOfBirth,
    bool withoutDateOfBirth = false,
  }) =>
      AdditionalNutrientRecommendationPolicy.derive(
        nutrientId: nutrientId,
        caloriesKcal: caloriesKcal,
        dateOfBirth: withoutDateOfBirth ? null : (dateOfBirth ?? dobForAge(36)),
        now: now,
      );

  group('display order', () {
    test('is exactly the seven approved nutrients, label-style', () {
      expect(AdditionalNutrientRecommendationPolicy.displayOrder, const [
        NutrientId.saturatedFat,
        NutrientId.transFat,
        NutrientId.addedSugar,
        NutrientId.sodium,
        NutrientId.calcium,
        NutrientId.phosphorus,
        NutrientId.vitaminD,
      ]);
    });

    test('does not include nutrients that are out of V1 scope', () {
      // Tracked as a nutrient fact does not mean approved as a target.
      for (final excluded in [
        NutrientId.energy,
        NutrientId.protein,
        NutrientId.carbohydrate,
        NutrientId.fat,
        NutrientId.fiber,
      ]) {
        expect(
          AdditionalNutrientRecommendationPolicy.displayOrder,
          isNot(contains(excluded)),
          reason: '$excluded',
        );
      }
    });
  });

  group('calorie-derived rules', () {
    test('saturated fat is 10% of Calories at 9 kcal/g, an inclusive ceiling',
        () {
      final result = derive(NutrientId.saturatedFat, caloriesKcal: 2000);

      expect(result.recommendedValue, closeTo(22.222, 0.001));
      expect(result.goalType, NutrientGoalType.maximum);
      expect(result.comparison, NutrientGoalComparison.atMost);
    });

    test('trans fat is 1% of Calories at 9 kcal/g', () {
      final result = derive(NutrientId.transFat, caloriesKcal: 2000);

      expect(result.recommendedValue, closeTo(2.222, 0.001));
      expect(result.comparison, NutrientGoalComparison.atMost);
    });

    test('added sugar is 10% of Calories at 4 kcal/g, a strict boundary', () {
      final result = derive(NutrientId.addedSugar, caloriesKcal: 2000);

      expect(result.recommendedValue, 50);
      expect(result.goalType, NutrientGoalType.maximum);
      expect(
        result.comparison,
        NutrientGoalComparison.lessThan,
        reason: 'The rule is "less than 10%", not "at most 10%".',
      );
    });

    test('all three scale with Calories', () {
      expect(
        derive(NutrientId.saturatedFat, caloriesKcal: 1800).recommendedValue,
        closeTo(20, 0.001),
      );
      expect(
        derive(NutrientId.transFat, caloriesKcal: 1800).recommendedValue,
        closeTo(2, 0.001),
      );
      expect(
        derive(NutrientId.addedSugar, caloriesKcal: 1800).recommendedValue,
        closeTo(45, 0.001),
      );
    });

    test('they are unavailable without a canonical Calories target', () {
      for (final nutrientId in [
        NutrientId.saturatedFat,
        NutrientId.transFat,
        NutrientId.addedSugar,
      ]) {
        final result = derive(nutrientId, caloriesKcal: null);
        expect(result.isAvailable, isFalse, reason: '$nutrientId');
        expect(
          AdditionalNutrientRecommendationPolicy.blockersFor(
            nutrientId: nutrientId,
            caloriesKcal: null,
            dateOfBirth: dobForAge(36),
            now: now,
          ),
          contains(NutrientRecommendationBlocker.caloriesMissing),
        );
      }
    });
  });

  group('fixed adult amounts', () {
    test('sodium is strictly under 2000 mg and ignores Calories', () {
      final result = derive(NutrientId.sodium, caloriesKcal: null);

      expect(result.recommendedValue, 2000);
      expect(result.goalType, NutrientGoalType.maximum);
      expect(result.comparison, NutrientGoalComparison.lessThan);
      expect(
        AdditionalNutrientRecommendationPolicy.dependsOnCalories(
          NutrientId.sodium,
        ),
        isFalse,
      );
    });

    test('phosphorus is a flat 700 mg adult target', () {
      final result = derive(NutrientId.phosphorus, caloriesKcal: null);

      expect(result.recommendedValue, 700);
      expect(result.goalType, NutrientGoalType.target);
      expect(result.comparison, NutrientGoalComparison.target);
    });

    test('phosphorus does not vary by age band above the minimum', () {
      for (final age in [19, 36, 50, 51, 70, 71, 90]) {
        expect(
          derive(NutrientId.phosphorus, dateOfBirth: dobForAge(age))
              .recommendedValue,
          700,
          reason: 'age $age',
        );
      }
    });
  });

  group('vitamin D age bands', () {
    test('15 mcg from 19 through 70', () {
      for (final age in [19, 36, 70]) {
        expect(
          derive(NutrientId.vitaminD, dateOfBirth: dobForAge(age))
              .recommendedValue,
          15,
          reason: 'age $age',
        );
      }
    });

    test('20 mcg from 71', () {
      for (final age in [71, 85]) {
        expect(
          derive(NutrientId.vitaminD, dateOfBirth: dobForAge(age))
              .recommendedValue,
          20,
          reason: 'age $age',
        );
      }
    });
  });

  group('calcium age bands', () {
    test('1000 mg from 19 through 50', () {
      for (final age in [19, 36, 50]) {
        expect(
          derive(NutrientId.calcium, dateOfBirth: dobForAge(age))
              .recommendedValue,
          1000,
          reason: 'age $age',
        );
      }
    });

    test('1200 mg from 71', () {
      for (final age in [71, 85]) {
        expect(
          derive(NutrientId.calcium, dateOfBirth: dobForAge(age))
              .recommendedValue,
          1200,
          reason: 'age $age',
        );
      }
    });

    test('51 through 70 is unavailable, not guessed', () {
      // This band differs by health reference sex, which Tio does not own as
      // canonical truth yet. Identity gender is not a substitute for it, so
      // the policy refuses rather than picking one.
      for (final age in [51, 60, 70]) {
        final result = derive(NutrientId.calcium, dateOfBirth: dobForAge(age));
        expect(result.isAvailable, isFalse, reason: 'age $age');
        expect(result.recommendedValue, isNull, reason: 'age $age');
      }
    });

    test('the 51-70 gap names reference sex, not a missing user input', () {
      final blockers = AdditionalNutrientRecommendationPolicy.blockersFor(
        nutrientId: NutrientId.calcium,
        caloriesKcal: 2000,
        dateOfBirth: dobForAge(60),
        now: now,
      );

      expect(
        blockers,
        contains(NutrientRecommendationBlocker.referenceSexUnavailable),
      );
      expect(
        blockers,
        isNot(contains(NutrientRecommendationBlocker.dateOfBirthMissing)),
        reason: 'The user supplied everything they can; the gap is ours.',
      );
    });

    test('the gap is calcium-only at that age', () {
      for (final nutrientId in [
        NutrientId.sodium,
        NutrientId.phosphorus,
        NutrientId.vitaminD,
        NutrientId.saturatedFat,
      ]) {
        expect(
          derive(nutrientId, dateOfBirth: dobForAge(60)).isAvailable,
          isTrue,
          reason: '$nutrientId',
        );
      }
    });
  });

  group('eligibility', () {
    test('every nutrient is unavailable without a date of birth', () {
      for (final nutrientId
          in AdditionalNutrientRecommendationPolicy.displayOrder) {
        final result = derive(nutrientId, withoutDateOfBirth: true);
        expect(result.isAvailable, isFalse, reason: '$nutrientId');
        expect(
          AdditionalNutrientRecommendationPolicy.blockersFor(
            nutrientId: nutrientId,
            caloriesKcal: 2000,
            dateOfBirth: null,
            now: now,
          ),
          contains(NutrientRecommendationBlocker.dateOfBirthMissing),
        );
      }
    });

    test('every nutrient is unavailable below the adult minimum', () {
      for (final nutrientId
          in AdditionalNutrientRecommendationPolicy.displayOrder) {
        expect(
          derive(nutrientId, dateOfBirth: dobForAge(18)).isAvailable,
          isFalse,
          reason: '$nutrientId',
        );
      }
    });

    test('19 is the first eligible age', () {
      expect(AdditionalNutrientRecommendationPolicy.minimumAge, 19);
      expect(derive(NutrientId.sodium, dateOfBirth: dobForAge(19)).isAvailable,
          isTrue);
      expect(derive(NutrientId.sodium, dateOfBirth: dobForAge(18)).isAvailable,
          isFalse);
    });

    test('a future date of birth is treated as unusable, not negative age', () {
      expect(
        derive(NutrientId.sodium, dateOfBirth: DateTime(2030, 1, 1))
            .isAvailable,
        isFalse,
      );
    });

    test('a birthday later this year has not happened yet', () {
      // 19 on paper by year subtraction, still 18 on the fixed clock.
      final result = AdditionalNutrientRecommendationPolicy.derive(
        nutrientId: NutrientId.sodium,
        caloriesKcal: 2000,
        dateOfBirth: DateTime(2007, 12, 31),
        now: now,
      );
      expect(result.isAvailable, isFalse);
    });
  });

  test('a nutrient outside V1 is rejected rather than silently defaulted', () {
    expect(
      () => derive(NutrientId.protein),
      throwsArgumentError,
    );
  });
}

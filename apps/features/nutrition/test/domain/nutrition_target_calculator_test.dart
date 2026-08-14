import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  const calculator = NutritionTargetCalculator();
  final fixedNow = DateTime(2026, 8, 14);

  group('NutritionTargetCalculator', () {
    test('calculates maintenance targets for male active profile accurately', () {
      final inputs = NutritionTargetInputs(
        heightCm: 175,
        weightKg: 70,
        dateOfBirth: DateTime(1996, 8, 14), // Age 30
        gender: 'male',
        activityLevel: 'active',
        primaryGoal: 'keep_fit',
      );

      final result = calculator.calculate(inputs, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationSuccess>());

      final rec = (result as NutritionTargetRecommendationSuccess).recommendation;
      // BMR = 10*70 + 6.25*175 - 5*30 + 5 = 700 + 1093.75 - 150 + 5 = 1648.75 -> 1649
      expect(rec.bmr, 1649);
      // TDEE = 1649 * 1.55 = 2555.95 -> 2556
      expect(rec.tdee, 2556);
      expect(rec.caloriesKcal, 2556);
      // Protein = 70 * 1.6 = 112g (448 kcal)
      expect(rec.proteinGrams, 112);
      // Fat = (2556 * 0.25) / 9 = 71g (639 kcal)
      expect(rec.fatGrams, 71);
      // Remaining = 2556 - 448 - 639 = 1469 kcal -> 1469 / 4 = 367.25 -> 367g
      expect(rec.carbsGrams, 367);
      // Fiber = (2556 / 1000) * 14 = 35.784 -> 36g
      expect(rec.fiberGrams, 36);
    });

    test('calculates weight loss with deficit and higher protein for female', () {
      final inputs = NutritionTargetInputs(
        heightCm: 165,
        weightKg: 65,
        dateOfBirth: DateTime(2001, 8, 14), // Age 25
        gender: 'female',
        activityLevel: 'light',
        primaryGoal: 'lose_weight',
        goalPaceKgPerWeek: 0.5,
      );

      final result = calculator.calculate(inputs, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationSuccess>());

      final rec = (result as NutritionTargetRecommendationSuccess).recommendation;
      // BMR = 10*65 + 6.25*165 - 5*25 - 161 = 650 + 1031.25 - 125 - 161 = 1395.25 -> 1395
      expect(rec.bmr, 1395);
      // TDEE = 1395 * 1.375 = 1918.125 -> 1918
      expect(rec.tdee, 1918);
      // Deficit = (0.5 * 7700) / 7 = 550 kcal -> 1918 - 550 = 1368 kcal
      expect(rec.caloriesKcal, 1368);
      // Protein = 65 * 2.0 = 130g (520 kcal)
      expect(rec.proteinGrams, 130);
      // Fat = (1368 * 0.25) / 9 = 38g (342 kcal)
      expect(rec.fatGrams, 38);
      // Carbs = (1368 - 520 - 342) / 4 = 506 / 4 = 126.5 -> 127g
      expect(rec.carbsGrams, 127);
      // Fiber = max(25, round((1368 / 1000) * 14)) = max(25, 19) = 25g
      expect(rec.fiberGrams, 25);
    });

    test('calculates muscle gain with surplus for other gender', () {
      final inputs = NutritionTargetInputs(
        heightCm: 180,
        weightKg: 75,
        dateOfBirth: DateTime(1998, 8, 14), // Age 28
        gender: 'other',
        activityLevel: 'very_active',
        primaryGoal: 'build_muscle',
        goalPaceKgPerWeek: 0.4,
      );

      final result = calculator.calculate(inputs, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationSuccess>());

      final rec = (result as NutritionTargetRecommendationSuccess).recommendation;
      // BMR = 10*75 + 6.25*180 - 5*28 - 78 = 750 + 1125 - 140 - 78 = 1657
      expect(rec.bmr, 1657);
      // TDEE = 1657 * 1.725 = 2858.325 -> 2858
      expect(rec.tdee, 2858);
      // Surplus = (0.4 * 5000) / 7 = 285.7 -> 286 kcal -> 2858 + 286 = 3144 kcal
      expect(rec.caloriesKcal, 3144);
      // Protein = 75 * 2.0 = 150g (600 kcal)
      expect(rec.proteinGrams, 150);
      // Fat = (3144 * 0.25) / 9 = 87.33 -> 87g (783 kcal)
      expect(rec.fatGrams, 87);
      // Carbs = (3144 - 600 - 783) / 4 = 1761 / 4 = 440.25 -> 440g
      expect(rec.carbsGrams, 440);
      // Fiber = (3144 / 1000) * 14 = 44g
      expect(rec.fiberGrams, 44);
    });

    test('enforces 1200 kcal floor on aggressive deficit', () {
      final inputs = NutritionTargetInputs(
        heightCm: 150,
        weightKg: 45,
        dateOfBirth: DateTime(2006, 8, 14), // Age 20
        gender: 'female',
        activityLevel: 'sedentary',
        primaryGoal: 'lose_weight',
        goalPaceKgPerWeek: 1.0,
      );

      final result = calculator.calculate(inputs, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationSuccess>());
      final rec = (result as NutritionTargetRecommendationSuccess).recommendation;
      expect(rec.caloriesKcal, 1200);
    });

    test('returns insufficient input when required demographic fields are missing', () {
      const inputs = NutritionTargetInputs(
        weightKg: 70,
      );

      final result = calculator.calculate(inputs, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationInsufficientInput>());

      final missing =
          (result as NutritionTargetRecommendationInsufficientInput).missingFields;
      expect(missing, containsAll(['heightCm', 'dateOfBirth', 'gender', 'activityLevel']));
    });

    test('returns invalid input when numeric values are zero or negative', () {
      final inputs = NutritionTargetInputs(
        heightCm: -170,
        weightKg: 70,
        dateOfBirth: DateTime(2000, 1, 1),
        gender: 'male',
        activityLevel: 'active',
      );

      final result = calculator.calculate(inputs, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationInvalidInput>());
    });
  });
}

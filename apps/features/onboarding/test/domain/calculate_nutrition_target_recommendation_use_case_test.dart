import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/src/domain/domain.dart';

void main() {
  const calculator = CalculateNutritionTargetRecommendationUseCase();
  final fixedNow = DateTime(2026, 8, 14);

  group('CalculateNutritionTargetRecommendationUseCase', () {
    test('calculates accurate target recommendations for standard profile', () {
      final profile = ProfileOnboardingDraft(
        name: 'Tio User',
        gender: ProfileGender.male,
        goals: const {ProfileGoal.keepFit},
        dateOfBirth: DateTime(1996, 8, 14), // Age 30
        heightCm: 175,
        currentWeightKg: 70,
        targetWeightKg: 70,
        activityLevel: ProfileActivityLevel.active,
        healthConditions: const {ProfileHealthCondition.none},
      );

      const targets = TargetsOnboardingDraft(
        dailySteps: 8000,
        waterMl: 2500,
        goalPaceKgPerWeek: 0.5,
      );

      final result = calculator(profile: profile, targets: targets, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationSuccess>());

      final rec = (result as NutritionTargetRecommendationSuccess).recommendation;
      expect(rec.bmr, 1649);
      expect(rec.tdee, 2556);
      expect(rec.caloriesKcal, 2556);
      expect(rec.proteinGrams, 112);
      expect(rec.fatGrams, 71);
      expect(rec.carbsGrams, 367);
      expect(rec.fiberGrams, 36);
    });

    test('calculates deficit calories and macros for weight loss goal', () {
      final profile = ProfileOnboardingDraft(
        name: 'Tio User',
        gender: ProfileGender.female,
        goals: const {ProfileGoal.loseWeight},
        dateOfBirth: DateTime(2001, 8, 14), // Age 25
        heightCm: 165,
        currentWeightKg: 65,
        targetWeightKg: 60,
        activityLevel: ProfileActivityLevel.light,
        healthConditions: const {ProfileHealthCondition.none},
      );

      const targets = TargetsOnboardingDraft(
        dailySteps: 10000,
        waterMl: 3000,
        goalPaceKgPerWeek: 0.5,
      );

      final result = calculator(profile: profile, targets: targets, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationSuccess>());

      final rec = (result as NutritionTargetRecommendationSuccess).recommendation;
      expect(rec.bmr, 1395);
      expect(rec.tdee, 1918);
      expect(rec.caloriesKcal, 1368);
      expect(rec.proteinGrams, 130);
      expect(rec.fatGrams, 38);
      expect(rec.carbsGrams, 127);
      expect(rec.fiberGrams, 25);
    });

    test('returns insufficient input when required demographic profile fields are missing', () {
      final profile = ProfileOnboardingDraft(
        name: 'Incomplete',
        gender: ProfileGender.male,
      );

      const targets = TargetsOnboardingDraft();

      final result = calculator(profile: profile, targets: targets, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationInsufficientInput>());

      final missing =
          (result as NutritionTargetRecommendationInsufficientInput).missingFields;
      expect(missing, containsAll(['currentWeightKg', 'heightCm', 'dateOfBirth', 'activityLevel']));
    });

    test('returns invalid input when numeric values are zero or negative', () {
      final profile = ProfileOnboardingDraft(
        name: 'Invalid',
        gender: ProfileGender.male,
        dateOfBirth: DateTime(2000, 1, 1),
        heightCm: -180,
        currentWeightKg: 70,
        activityLevel: ProfileActivityLevel.active,
      );

      const targets = TargetsOnboardingDraft();

      final result = calculator(profile: profile, targets: targets, now: fixedNow);
      expect(result, isA<NutritionTargetRecommendationInvalidInput>());
    });
  });
}

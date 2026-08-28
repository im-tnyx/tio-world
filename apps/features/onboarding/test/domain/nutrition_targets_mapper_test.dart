import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('NutritionTargetsMapper', () {
    const mapper = NutritionTargetsMapper();
    const calculator = CalculateNutritionTargetRecommendationUseCase();

    test('maps the existing recommendation losslessly into canonical targets',
        () {
      final profile = _validProfile();
      const targets = TargetsOnboardingDraft(
        dailySteps: 9000,
        goalPaceKgPerWeek: 0.0,
      );
      final expectedResult = calculator(profile: profile, targets: targets);
      expect(expectedResult, isA<nutrition_owner.NutritionTargetRecommendationSuccess>());
      final expected =
          (expectedResult as nutrition_owner.NutritionTargetRecommendationSuccess)
              .recommendation;

      final mapped = mapper.map(
        OnboardingDraft(
          selectedMode: AppMode.workout,
          profile: profile,
          targets: targets,
        ),
      );

      expect(mapped.caloriesKcal, expected.caloriesKcal);
      expect(mapped.proteinGrams, expected.proteinGrams.toDouble());
      expect(mapped.carbohydrateGrams, expected.carbsGrams.toDouble());
      expect(mapped.fatGrams, expected.fatGrams.toDouble());
      expect(mapped.fiberGrams, expected.fiberGrams.toDouble());
      expect(
        mapped.customizationState,
        nutrition_owner.NutritionTargetCustomizationState.recommended,
      );
      expect(mapped.customizedFields, isEmpty);
      expect(mapped.recommendationMetadata['source'], 'onboarding');
      expect(mapped.recommendationMetadata['bmr'], expected.bmr);
      expect(mapped.recommendationMetadata['tdee'], expected.tdee);
    });

    test('insufficient inputs remain canonical unknowns without fake numbers',
        () {
      final mapped = mapper.map(
        OnboardingDraft(
          selectedMode: AppMode.nutrition,
          profile: ProfileOnboardingDraft(name: 'Tio User'),
        ),
      );

      expect(mapped.caloriesKcal, isNull);
      expect(mapped.proteinGrams, isNull);
      expect(mapped.carbohydrateGrams, isNull);
      expect(mapped.fatGrams, isNull);
      expect(mapped.fiberGrams, isNull);
      expect(
        mapped.customizationState,
        nutrition_owner.NutritionTargetCustomizationState.unknown,
      );
      expect(mapped.customizedFields, isEmpty);
      expect(mapped.recommendationMetadata, {'source': 'onboarding'});
    });

    test('non-directional goal does not consume dormant pace intent', () {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        profile: _validProfile(),
        targets: const TargetsOnboardingDraft(
          dailySteps: 9000,
          goalPaceKgPerWeek: 1.5,
        ),
      );

      final mapped = mapper.map(draft);
      final neutralResult = calculator(
        profile: _validProfile().copyWith(clearTargetWeightKg: true),
        targets: const TargetsOnboardingDraft(
          dailySteps: 9000,
          goalPaceKgPerWeek: 0.0,
        ),
      );
      final expected =
          (neutralResult as nutrition_owner.NutritionTargetRecommendationSuccess)
              .recommendation;

      expect(mapped.caloriesKcal, expected.caloriesKcal);
      expect(mapped.recommendationMetadata['tdee'], expected.tdee);
    });
  });
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    name: 'Tio User',
    gender: ProfileGender.female,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(1996, 6, 15),
    heightCm: 165,
    currentWeightKg: 60,
    targetWeightKg: 58,
    targetWeightDirection: GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

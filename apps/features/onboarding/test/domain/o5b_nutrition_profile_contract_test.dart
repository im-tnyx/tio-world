import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('O5B Nutrition Profile contract', () {
    test('flow owns Diet Type then Allergies/Restrictions', () {
      const flow = NutritionProfileFlowPlan();
      expect(
        flow.steps,
        const [
          NutritionProfileStepId.dietType,
          NutritionProfileStepId.allergiesRestrictions,
        ],
      );
    });

    test('unanswered allergies differ from explicit None', () {
      const unanswered = NutritionOnboardingDraft();
      const explicitNone = NutritionOnboardingDraft(
        allergyRestrictions: {NutritionAllergyRestriction.none},
      );
      expect(unanswered.allergyRestrictions, isNull);
      expect(explicitNone.allergyRestrictions, {
        NutritionAllergyRestriction.none,
      });
      expect(unanswered, isNot(explicitNone));
    });

    test('validator requires answers and enforces exclusive None', () {
      const validator = NutritionProfileStepValidator();
      expect(
        validator.validateCurrentStep(const NutritionOnboardingDraft()),
        isNotNull,
      );
      expect(
        validator.validateCurrentStep(
          const NutritionOnboardingDraft(
            currentStepId: NutritionProfileStepId.allergiesRestrictions,
            dietType: NutritionDietType.vegan,
            allergyRestrictions: {
              NutritionAllergyRestriction.none,
              NutritionAllergyRestriction.gluten,
            },
          ),
        ),
        isNotNull,
      );
      expect(
        validator.validateCurrentStep(
          const NutritionOnboardingDraft(
            currentStepId: NutritionProfileStepId.allergiesRestrictions,
            dietType: NutritionDietType.vegan,
            allergyRestrictions: {NutritionAllergyRestriction.none},
          ),
        ),
        isNull,
      );
    });
  });
}

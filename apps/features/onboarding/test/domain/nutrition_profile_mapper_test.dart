import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('NutritionProfileMapper', () {
    const mapper = NutritionProfileMapper();

    test('keeps unanswered Nutrition context unknown', () {
      expect(
        mapper.map(const NutritionOnboardingDraft()),
        const nutrition_owner.NutritionProfileData(),
      );
    });

    test('maps diet and explicit None to preferred diet plus empty allergies',
        () {
      expect(
        mapper.map(
          const NutritionOnboardingDraft(
            dietType: NutritionDietType.vegan,
            allergyRestrictions: {NutritionAllergyRestriction.none},
          ),
        ),
        const nutrition_owner.NutritionProfileData(
          preferredDiet: 'vegan',
          allergies: {},
        ),
      );
    });

    test('maps selected restrictions to stable storage strings', () {
      final mapped = mapper.map(
        const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegetarian,
          allergyRestrictions: {
            NutritionAllergyRestriction.gluten,
            NutritionAllergyRestriction.nuts,
          },
        ),
      );

      expect(mapped.preferredDiet, 'vegetarian');
      expect(mapped.allergies, {'gluten', 'nuts'});
      expect(mapped.dislikedFoods, isNull);
      expect(mapped.medicalConditions, isNull);
    });

    test('rejects invalid empty answered allergy set', () {
      expect(
        () => mapper.map(
          const NutritionOnboardingDraft(allergyRestrictions: {}),
        ),
        throwsArgumentError,
      );
    });

    test('rejects None mixed with real restrictions', () {
      expect(
        () => mapper.map(
          const NutritionOnboardingDraft(
            allergyRestrictions: {
              NutritionAllergyRestriction.none,
              NutritionAllergyRestriction.gluten,
            },
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}

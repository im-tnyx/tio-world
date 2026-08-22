import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('NutritionProfileMapper', () {
    const mapper = NutritionProfileMapper();

    test('keeps unanswered Nutrition context unknown', () {
      final mapped = mapper.map(const NutritionOnboardingDraft());

      expect(mapped.preferredDiet, isNull);
      expect(mapped.allergies, isNull);
      expect(mapped.dislikedFoods, isNull);
      expect(mapped.medicalConditions, isNull);
    });

    test('maps diet and explicit None to preferred diet plus empty allergies',
        () {
      final mapped = mapper.map(
        const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegan,
          allergyRestrictions: {NutritionAllergyRestriction.none},
        ),
      );

      expect(mapped.preferredDiet, 'vegan');
      expect(mapped.allergies, isEmpty);
      expect(mapped.dislikedFoods, isNull);
      expect(mapped.medicalConditions, isNull);
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

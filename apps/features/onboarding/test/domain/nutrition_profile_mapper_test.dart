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

    test('carries the "Other" free text through to canonical storage', () {
      // Regression: this text used to be collected and then silently dropped
      // at completion, so an unlisted diet or allergy never reached storage
      // and could not be honoured by later diet planning.
      final mapped = mapper.map(
        const NutritionOnboardingDraft(
          dietType: NutritionDietType.other,
          otherDietType: '  Jain  ',
          allergyRestrictions: {NutritionAllergyRestriction.other},
          otherAllergyRestriction: ' Sesame ',
        ),
      );

      expect(mapped.preferredDiet, 'other');
      expect(mapped.otherDietType, 'Jain');
      expect(mapped.allergies, {'other'});
      expect(mapped.otherAllergyRestriction, 'Sesame');
    });

    test('blank "Other" text stays null while the selection survives', () {
      final mapped = mapper.map(
        const NutritionOnboardingDraft(
          dietType: NutritionDietType.other,
          allergyRestrictions: {NutritionAllergyRestriction.other},
        ),
      );

      // Dropping the token instead would turn an answered allergy question
      // back into "None", which is a different and wrong answer.
      expect(mapped.preferredDiet, 'other');
      expect(mapped.allergies, {'other'});
      expect(mapped.otherDietType, isNull);
      expect(mapped.otherAllergyRestriction, isNull);
    });

    test('elaboration is dropped when its "Other" selection is not active', () {
      final mapped = mapper.map(
        const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegan,
          otherDietType: 'Jain',
          allergyRestrictions: {NutritionAllergyRestriction.nuts},
          otherAllergyRestriction: 'Sesame',
        ),
      );

      // Stale draft text must not resurface as an orphan describing nothing.
      expect(mapped.otherDietType, isNull);
      expect(mapped.otherAllergyRestriction, isNull);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const mapper = NutritionAwareOnboardingDraftSnapshotDtoMapper();

  test('round-trips typed Nutrition Profile draft answers', () {
    final snapshot = OnboardingDraftSnapshot(
      draft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.nutritionProfile,
        nutrition: const NutritionOnboardingDraft(
          currentStepId: NutritionProfileStepId.allergiesRestrictions,
          dietType: NutritionDietType.other,
          otherDietType: 'Jain',
          allergyRestrictions: {
            NutritionAllergyRestriction.gluten,
            NutritionAllergyRestriction.other,
          },
          otherAllergyRestriction: 'Sesame',
        ),
      ),
    );

    final json = mapper.toJson(snapshot);
    final nutrition = json['nutrition'] as Map<String, dynamic>;
    expect(
      json['schema_version'],
      OnboardingDraftSnapshot.currentSchemaVersion,
    );
    expect(nutrition['current_step_id'], 'allergiesRestrictions');
    expect(nutrition['diet_type'], 'other');
    expect(nutrition['other_diet_type'], 'Jain');
    expect(
      nutrition['allergy_restrictions'],
      containsAll(['gluten', 'other']),
    );
    expect(nutrition['other_allergy_restriction'], 'Sesame');

    final restored = mapper.fromJson(json).draft.nutrition;
    expect(restored.currentStepId, NutritionProfileStepId.allergiesRestrictions);
    expect(restored.dietType, NutritionDietType.other);
    expect(restored.otherDietType, 'Jain');
    expect(restored.allergyRestrictions, {
      NutritionAllergyRestriction.gluten,
      NutritionAllergyRestriction.other,
    });
    expect(restored.otherAllergyRestriction, 'Sesame');
  });

  test('older Nutrition payload defaults missing Other details to empty', () {
    final restored = mapper.fromJson(<String, dynamic>{
      'schema_version': 4,
      'selected_mode': 'nutrition',
      'current_step_id': 'nutritionProfile',
      'nutrition': <String, dynamic>{
        'current_step_id': 'allergiesRestrictions',
        'diet_type': 'other',
        'allergy_restrictions': ['other'],
      },
    }).draft.nutrition;

    expect(restored.dietType, NutritionDietType.other);
    expect(restored.otherDietType, isEmpty);
    expect(restored.allergyRestrictions, {NutritionAllergyRestriction.other});
    expect(restored.otherAllergyRestriction, isEmpty);
  });

  test('legacy payload without Nutrition remains unanswered', () {
    final restored = mapper.fromJson(<String, dynamic>{
      'schema_version': 4,
      'selected_mode': 'nutrition',
      'current_step_id': 'review',
    });
    expect(
      restored.draft.nutrition.currentStepId,
      NutritionProfileStepId.dietType,
    );
    expect(restored.draft.nutrition.dietType, isNull);
    expect(restored.draft.nutrition.otherDietType, isEmpty);
    expect(restored.draft.nutrition.allergyRestrictions, isNull);
    expect(restored.draft.nutrition.otherAllergyRestriction, isEmpty);
  });
}

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
          dietType: NutritionDietType.nonVegetarian,
          allergyRestrictions: {
            NutritionAllergyRestriction.gluten,
            NutritionAllergyRestriction.nuts,
          },
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
    expect(nutrition['diet_type'], 'non_vegetarian');
    expect(nutrition['allergy_restrictions'], containsAll(['gluten', 'nuts']));

    final restored = mapper.fromJson(json).draft.nutrition;
    expect(restored.currentStepId, NutritionProfileStepId.allergiesRestrictions);
    expect(restored.dietType, NutritionDietType.nonVegetarian);
    expect(restored.allergyRestrictions, {
      NutritionAllergyRestriction.gluten,
      NutritionAllergyRestriction.nuts,
    });
  });

  test('legacy payload without Nutrition remains unanswered', () {
    final restored = mapper.fromJson(<String, dynamic>{
      'schema_version': 4,
      'selected_mode': 'nutrition',
      'current_step_id': 'review',
    });
    expect(restored.draft.nutrition.currentStepId, NutritionProfileStepId.dietType);
    expect(restored.draft.nutrition.dietType, isNull);
    expect(restored.draft.nutrition.allergyRestrictions, isNull);
  });
}

import '../models/models.dart';

class NutritionProfileStepValidator {
  const NutritionProfileStepValidator();

  String? validateCurrentStep(NutritionOnboardingDraft draft) {
    return switch (draft.currentStepId) {
      NutritionProfileStepId.dietType => draft.dietType == null
          ? 'Choose the diet type that best matches you.'
          : null,
      NutritionProfileStepId.allergiesRestrictions =>
        _validateAllergies(draft.allergyRestrictions),
    };
  }

  String? _validateAllergies(Set<NutritionAllergyRestriction>? values) {
    if (values == null || values.isEmpty) {
      return 'Choose any allergies or restrictions, or select None.';
    }
    if (values.contains(NutritionAllergyRestriction.none) && values.length > 1) {
      return 'None cannot be combined with another allergy or restriction.';
    }
    return null;
  }
}

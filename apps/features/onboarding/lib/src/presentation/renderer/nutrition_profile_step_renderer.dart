import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/nutrition/allergies_restrictions_screen.dart';
import '../screens/nutrition/diet_type_screen.dart';
import '../state/state.dart';

class NutritionProfileStepRenderer extends StatelessWidget {
  const NutritionProfileStepRenderer({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final draft = state.draft.nutrition;
    final errorText = state.validationErrors[draft.currentStepId.name];

    return switch (draft.currentStepId) {
      NutritionProfileStepId.dietType => DietTypeScreen(
          selectedDietType: draft.dietType,
          otherText: draft.otherDietType,
          onSelected: controller.updateNutritionDietType,
          onOtherTextChanged: controller.updateNutritionOtherDietType,
          errorText: errorText,
        ),
      NutritionProfileStepId.allergiesRestrictions =>
        AllergiesRestrictionsScreen(
          selectedRestrictions: draft.allergyRestrictions,
          otherText: draft.otherAllergyRestriction,
          onToggled: controller.toggleNutritionAllergyRestriction,
          onOtherTextChanged:
              controller.updateNutritionOtherAllergyRestriction,
          errorText: errorText,
        ),
    };
  }
}

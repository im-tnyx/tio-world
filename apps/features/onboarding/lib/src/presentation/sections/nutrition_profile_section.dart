import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../renderer/nutrition_profile_step_renderer.dart';
import '../state/state.dart';

class NutritionProfileSection extends StatelessWidget {
  const NutritionProfileSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.nutritionProfile ||
        state.currentSection != OnboardingSectionId.nutritionProfile) {
      throw StateError(
        'NutritionProfileSection can only render the nutritionProfile section.',
      );
    }
    if (!state.nutritionProfileFlowPlan
        .contains(state.draft.nutrition.currentStepId)) {
      throw StateError('Invalid Nutrition Profile child step.');
    }
    return NutritionProfileStepRenderer(
      state: state,
      controller: controller,
    );
  }
}

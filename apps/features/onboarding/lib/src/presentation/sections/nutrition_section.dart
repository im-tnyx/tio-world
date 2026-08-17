import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../renderer/nutrition_step_renderer.dart';
import '../state/state.dart';

class NutritionSection extends StatelessWidget {
  const NutritionSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.nutritionPreferences ||
        state.currentSection != OnboardingSectionId.nutrition) {
      throw StateError(
        'NutritionSection can only render the nutrition preferences step.',
      );
    }

    return NutritionStepRenderer(state: state);
  }
}

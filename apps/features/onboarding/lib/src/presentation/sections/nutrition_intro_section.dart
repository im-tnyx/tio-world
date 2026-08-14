import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/nutrition/nutrition_intro_screen.dart';
import '../state/state.dart';

class NutritionIntroSection extends StatelessWidget {
  const NutritionIntroSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.nutritionIntro ||
        state.currentSection != OnboardingSectionId.nutritionIntro) {
      throw StateError(
        'NutritionIntroSection can only render the nutrition intro step.',
      );
    }

    return const NutritionIntroScreen();
  }
}

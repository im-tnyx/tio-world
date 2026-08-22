import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../renderer/target_step_renderer.dart';
import '../screens/targets/targets_screen_components.dart';
import '../state/state.dart';

class NutritionGoalsSection extends StatelessWidget {
  const NutritionGoalsSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.nutritionGoals ||
        state.currentSection != OnboardingSectionId.nutritionGoals) {
      throw StateError(
        'NutritionGoalsSection can only render the nutritionGoals step.',
      );
    }

    return TargetsFlowPlanScope(
      flowPlan: state.targetsFlowPlan,
      child: TargetStepRenderer(state: state, controller: controller),
    );
  }
}

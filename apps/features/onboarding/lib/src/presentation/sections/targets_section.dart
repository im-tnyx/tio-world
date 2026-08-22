import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../renderer/target_step_renderer.dart';
import '../screens/targets/targets_screen_components.dart';
import '../state/state.dart';

class TargetsSection extends StatelessWidget {
  const TargetsSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.targets ||
        state.currentSection != OnboardingSectionId.targets) {
      throw StateError(
        'TargetsSection can only render the targets step.',
      );
    }

    return TargetsFlowPlanScope(
      flowPlan: state.targetsFlowPlan,
      child: TargetStepRenderer(state: state, controller: controller),
    );
  }
}

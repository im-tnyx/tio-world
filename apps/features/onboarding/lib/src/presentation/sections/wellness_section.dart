import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../renderer/target_step_renderer.dart';
import '../screens/targets/targets_screen_components.dart';
import '../state/state.dart';

/// Runtime section boundary for Wellness-owned onboarding targets.
///
/// The serialized child/value container remains [TargetsOnboardingDraft] for
/// compatibility during O4B. Existing target screens are reused unchanged.
class WellnessSection extends StatelessWidget {
  const WellnessSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.wellnessGoals ||
        state.currentSection != OnboardingSectionId.wellnessGoals) {
      throw StateError(
        'WellnessSection can only render the wellnessGoals step.',
      );
    }

    final childStep = state.draft.targets.currentStepId;
    if (!state.wellnessFlowPlan.contains(childStep)) {
      throw StateError(
        'WellnessSection cannot render non-Wellness child ${childStep.name}.',
      );
    }

    return TargetsFlowPlanScope(
      flowPlan: TargetsFlowPlan(steps: state.wellnessFlowPlan.steps),
      child: TargetStepRenderer(state: state, controller: controller),
    );
  }
}

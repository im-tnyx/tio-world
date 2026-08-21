import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../renderer/profile_step_renderer.dart';
import '../screens/profile/profile_screen_components.dart';
import '../state/state.dart';

class ProfileSection extends StatelessWidget {
  const ProfileSection(
      {required this.state, required this.controller, super.key});

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.profileBasics ||
        state.currentSection != OnboardingSectionId.profile) {
      throw StateError('ProfileSection can only render the profile step.');
    }

    return ProfileFlowPlanScope(
      flowPlan: state.profileFlowPlan,
      child: ProfileStepRenderer(state: state, controller: controller),
    );
  }
}

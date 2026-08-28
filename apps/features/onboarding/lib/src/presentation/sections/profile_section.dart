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
    final section = state.currentSection;
    final isProfileSection = section == OnboardingSectionId.profile ||
        section == OnboardingSectionId.userProfile;
    if (state.stepId != OnboardingStepId.profileBasics || !isProfileSection) {
      throw StateError('ProfileSection can only render the Profile section.');
    }
    if (!state.profileFlowPlan.contains(state.draft.profile.currentStepId)) {
      throw StateError(
        'Common Profile cannot render Body-owned child '
        '${state.draft.profile.currentStepId.name}.',
      );
    }

    return ProfileFlowPlanScope(
      flowPlan: state.profileFlowPlan,
      child: ProfileStepRenderer(state: state, controller: controller),
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/profile/mobile_screen.dart';
import '../state/state.dart';

class MobileSection extends StatelessWidget {
  const MobileSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.mobile ||
        state.currentSection != OnboardingSectionId.mobile) {
      throw StateError('MobileSection can only render the mobile step.');
    }

    final draft = state.draft.profile;

    return MobileScreen(
      initialMobile: draft.mobile,
      isVerified: draft.isMobileVerified,
      onMobileChanged: controller.updateProfileMobile,
      onVerificationCompleted: controller.updateProfileMobileVerified,
    );
  }
}

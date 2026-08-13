import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/app_mode/app_mode_screen.dart';
import '../state/state.dart';

class AppModeSection extends StatelessWidget {
  const AppModeSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.mode) {
      throw StateError('AppModeSection can only render the mode step.');
    }

    return AppModeScreen(
      selectedMode: state.draft.selectedMode,
      enabled: !state.isBusy,
      onModeSelected: controller.selectMode,
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../renderer/workout_step_renderer.dart';
import '../state/state.dart';

class WorkoutSection extends StatelessWidget {
  const WorkoutSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.workoutPreferences ||
        state.currentSection != OnboardingSectionId.workout) {
      throw StateError(
        'WorkoutSection can only render the workout preferences step.',
      );
    }

    return WorkoutStepRenderer(state: state, controller: controller);
  }
}

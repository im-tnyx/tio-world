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
    final isWorkoutSection =
        state.currentSection == OnboardingSectionId.workoutProfile ||
            state.currentSection == OnboardingSectionId.workout;
    if (state.stepId != OnboardingStepId.workoutProfile || !isWorkoutSection) {
      throw StateError(
        'WorkoutSection can only render the active workoutProfile step.',
      );
    }

    return WorkoutStepRenderer(state: state, controller: controller);
  }
}

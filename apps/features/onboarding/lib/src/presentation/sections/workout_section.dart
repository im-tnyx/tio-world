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
    final isWorkoutProfile =
        state.stepId == OnboardingStepId.workoutProfile &&
            (state.currentSection == OnboardingSectionId.workoutProfile ||
                state.currentSection == OnboardingSectionId.workout);
    final isWorkoutTargets =
        state.stepId == OnboardingStepId.workoutTargets &&
            state.currentSection == OnboardingSectionId.workoutTargets;
    if (!isWorkoutProfile && !isWorkoutTargets) {
      throw StateError(
        'WorkoutSection can only render an active canonical Workout section.',
      );
    }

    return WorkoutStepRenderer(state: state, controller: controller);
  }
}

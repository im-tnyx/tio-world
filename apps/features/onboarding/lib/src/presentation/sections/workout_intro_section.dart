import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/workout/workout_intro_screen.dart';
import '../state/state.dart';

class WorkoutIntroSection extends StatelessWidget {
  const WorkoutIntroSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.workoutIntro ||
        state.currentSection != OnboardingSectionId.workoutIntro) {
      throw StateError(
        'WorkoutIntroSection can only render the workout intro step.',
      );
    }

    return WorkoutIntroScreen(
      selectedChoice: state.draft.workoutIntroChoice,
      onChoiceSelected: controller.selectWorkoutIntroChoice,
      enabled: !state.isBusy,
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../screens/compatibility/compatibility_onboarding_screen.dart';
import '../state/state.dart';

class OnboardingCompatibilitySection extends StatelessWidget {
  const OnboardingCompatibilitySection({
    required this.state,
    required this.section,
    super.key,
  });

  final OnboardingState state;
  final OnboardingSectionId section;

  @override
  Widget build(BuildContext context) {
    if (state.currentSection != section) {
      throw StateError(
        'Compatibility section ${section.name} cannot render '
        '${state.currentSection.name}.',
      );
    }

    return switch (state.stepId) {
      OnboardingStepId.mode => throw StateError(
          'The mode step must render through AppModeSection.',
        ),
      OnboardingStepId.profileBasics => throw StateError(
          'The profile step must render through ProfileSection.',
        ),
      OnboardingStepId.mobile => throw StateError(
          'The mobile step must render through MobileSection.',
        ),
      OnboardingStepId.workoutIntro => throw StateError(
          'The workout intro step must render through WorkoutIntroSection.',
        ),
      OnboardingStepId.workoutPreferences => throw StateError(
          'The workout preferences step must render through WorkoutSection.',
        ),
      OnboardingStepId.nutritionIntro => throw StateError(
          'The nutrition intro step must render through NutritionIntroSection.',
        ),
      OnboardingStepId.nutritionPreferences =>
        throw StateError(
          'The nutrition preferences step must render through NutritionSection.',
        ),
      OnboardingStepId.targets => throw StateError(
          'The targets step must render through TargetsSection.',
        ),
      OnboardingStepId.review =>
        CompatibilityReviewScreen(mode: state.draft.selectedMode),
    };
  }
}

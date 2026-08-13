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
      OnboardingStepId.workoutIntro => throw StateError(
          'The workout intro step must render through WorkoutIntroSection.',
        ),
      OnboardingStepId.workoutPreferences =>
        const CompatibilityOnboardingScreen(
          title: 'Training preferences',
          description:
              'Workout-owned defaults such as experience, schedule, and '
              'equipment will replace this preview.',
          highlights: [
            'Validation remains planned with the real settings inputs.',
            'No workout calculations are finalized in onboarding yet.',
            'Continue advances through the selected App Mode path only.',
          ],
        ),
      OnboardingStepId.nutritionIntro => const CompatibilityOnboardingScreen(
          title: 'Nutrition setup',
          description:
              'Nutrition onboarding will introduce target and meal-context '
              'setup here once the owning feature contracts are approved.',
          highlights: [
            'Meal Plan remains a later nutrition slice.',
            'This preview keeps the route and progress behavior realistic.',
            'No nutrition data is persisted from this compatibility step.',
          ],
        ),
      OnboardingStepId.nutritionPreferences =>
        const CompatibilityOnboardingScreen(
          title: 'Nutrition preferences',
          description:
              'Nutrition-owned preferences and targets will replace this '
              'preview after their validated fields are approved.',
          highlights: [
            'Targets stay module-owned and are not calculated here yet.',
            'Hybrid mode still keeps the combined step order intact.',
            'Continue remains fixed at the bottom of the parent shell.',
          ],
        ),
      OnboardingStepId.targets => const CompatibilityOnboardingScreen(
          title: 'Your targets',
          description:
              'Prepared recommendations and explicit overrides will land here '
              'in a later slice. The current route preview keeps the full '
              'parent flow visible without inventing target logic.',
          highlights: [
            'No auto-calculated target formulas are claimed yet.',
            'Cross-feature review remains a planned step owner boundary.',
            'The next action label changes to Review on this step.',
          ],
        ),
      OnboardingStepId.review =>
        CompatibilityReviewScreen(mode: state.draft.selectedMode),
    };
  }
}

import '../models/onboarding_progress_item.dart';
import '../models/onboarding_step_id.dart';
import '../models/profile_step_id.dart';
import '../models/target_step_id.dart';
import '../models/workout_step_id.dart';

/// Pure domain model representing the ordered, active visible screens
/// in the continuous onboarding progress journey.
class OnboardingProgressPlan {
  const OnboardingProgressPlan({
    required this.items,
  });

  /// Flattened list of all active visible screens excluding AppMode.
  final List<OnboardingProgressItem> items;

  /// Total number of visible progress screens in the active flow.
  int get totalSteps => items.length;

  /// Finds the 0-indexed position of the currently visible child screen.
  ///
  /// Returns -1 for AppMode or if the screen is not in the active plan.
  int indexOfCurrentScreen({
    required OnboardingStepId stepId,
    required ProfileStepId profileStepId,
    required WorkoutStepId workoutStepId,
    required TargetStepId targetStepId,
  }) {
    switch (stepId) {
      case OnboardingStepId.mode:
        return -1;
      case OnboardingStepId.profileBasics:
        return items.indexWhere(
          (item) => item is ProfileProgressItem && item.stepId == profileStepId,
        );
      case OnboardingStepId.bodyGoal:
        return items.indexWhere(
          (item) =>
              item is BodyGoalProgressItem && item.stepId == profileStepId,
        );
      case OnboardingStepId.mobile:
        return items.indexWhere((item) => item is MobileProgressItem);
      case OnboardingStepId.workoutIntro:
        return items.indexWhere((item) => item is WorkoutIntroProgressItem);
      case OnboardingStepId.workoutPreferences:
        return items.indexWhere(
          (item) => item is WorkoutProgressItem && item.stepId == workoutStepId,
        );
      case OnboardingStepId.nutritionIntro:
        return items.indexWhere((item) => item is NutritionIntroProgressItem);
      case OnboardingStepId.nutritionPreferences:
        return items.indexWhere((item) => item is NutritionPreferencesProgressItem);
      case OnboardingStepId.targets:
        return items.indexWhere(
          (item) => item is TargetsProgressItem && item.stepId == targetStepId,
        );
      case OnboardingStepId.review:
        return items.indexWhere((item) => item is ReviewProgressItem);
      case OnboardingStepId.userProfile:
      case OnboardingStepId.wellnessGoals:
      case OnboardingStepId.nutritionProfile:
      case OnboardingStepId.workoutProfile:
      case OnboardingStepId.nutritionGoals:
      case OnboardingStepId.workoutTargets:
      case OnboardingStepId.healthConnections:
      case OnboardingStepId.planBuilding:
        throw StateError(
          'Future onboarding step ${stepId.name} is not active in the current flow.',
        );
    }
  }

  /// Calculates the normalized 0.0..1.0 progress fraction for the current screen.
  ///
  /// For the first visible screen (index 0), progress is 1 / totalSteps (> 0.0).
  /// For the final Review screen (index totalSteps - 1), progress is exactly 1.0.
  double progressFor({
    required OnboardingStepId stepId,
    required ProfileStepId profileStepId,
    required WorkoutStepId workoutStepId,
    required TargetStepId targetStepId,
  }) {
    if (stepId == OnboardingStepId.mode || totalSteps == 0) {
      return 0.0;
    }
    final index = indexOfCurrentScreen(
      stepId: stepId,
      profileStepId: profileStepId,
      workoutStepId: workoutStepId,
      targetStepId: targetStepId,
    );
    if (index < 0) return 0.0;
    final value = (index + 1) / totalSteps;
    return value.clamp(0.0, 1.0);
  }
}

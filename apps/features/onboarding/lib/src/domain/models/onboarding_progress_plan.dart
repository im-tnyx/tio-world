import '../models/nutrition_profile_step_id.dart';
import '../models/onboarding_progress_item.dart';
import '../models/onboarding_step_id.dart';
import '../models/profile_step_id.dart';
import '../models/target_step_id.dart';
import '../models/workout_step_id.dart';

/// Pure domain model representing the ordered, active visible screens
/// in the continuous onboarding progress journey.
class OnboardingProgressPlan {
  const OnboardingProgressPlan({required this.items});

  final List<OnboardingProgressItem> items;
  int get totalSteps => items.length;

  int indexOfCurrentScreen({
    required OnboardingStepId stepId,
    required ProfileStepId profileStepId,
    required WorkoutStepId workoutStepId,
    required TargetStepId targetStepId,
    NutritionProfileStepId nutritionProfileStepId =
        NutritionProfileStepId.dietType,
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
      case OnboardingStepId.wellnessGoals:
        return items.indexWhere(
          (item) =>
              item is WellnessProgressItem && item.stepId == targetStepId,
        );
      case OnboardingStepId.nutritionProfile:
        return items.indexWhere(
          (item) =>
              item is NutritionProfileProgressItem &&
              item.stepId == nutritionProfileStepId,
        );
      case OnboardingStepId.mobile:
        return items.indexWhere((item) => item is MobileProgressItem);
      case OnboardingStepId.workoutIntro:
        return items.indexWhere((item) => item is WorkoutIntroProgressItem);
      case OnboardingStepId.workoutProfile:
      case OnboardingStepId.workoutTargets:
        return items.indexWhere(
          (item) => item is WorkoutProgressItem && item.stepId == workoutStepId,
        );
      case OnboardingStepId.nutritionIntro:
        return items.indexWhere((item) => item is NutritionIntroProgressItem);
      case OnboardingStepId.nutritionPreferences:
        return items.indexWhere(
          (item) => item is NutritionPreferencesProgressItem,
        );
      case OnboardingStepId.nutritionGoals:
        return items.indexWhere(
          (item) =>
              item is NutritionGoalsProgressItem && item.stepId == targetStepId,
        );
      case OnboardingStepId.targets:
        return items.indexWhere(
          (item) => item is TargetsProgressItem && item.stepId == targetStepId,
        );
      case OnboardingStepId.healthConnections:
        return items.indexWhere(
          (item) => item is HealthConnectionsProgressItem,
        );
      case OnboardingStepId.review:
        return items.indexWhere((item) => item is ReviewProgressItem);
      case OnboardingStepId.userProfile:
      case OnboardingStepId.planBuilding:
        throw StateError(
          'Future onboarding step ${stepId.name} is not active in the current flow.',
        );
    }
  }

  double progressFor({
    required OnboardingStepId stepId,
    required ProfileStepId profileStepId,
    required WorkoutStepId workoutStepId,
    required TargetStepId targetStepId,
    NutritionProfileStepId nutritionProfileStepId =
        NutritionProfileStepId.dietType,
  }) {
    if (stepId == OnboardingStepId.mode || totalSteps == 0) return 0.0;
    final index = indexOfCurrentScreen(
      stepId: stepId,
      profileStepId: profileStepId,
      workoutStepId: workoutStepId,
      targetStepId: targetStepId,
      nutritionProfileStepId: nutritionProfileStepId,
    );
    if (index < 0) return 0.0;
    return ((index + 1) / totalSteps).clamp(0.0, 1.0);
  }
}

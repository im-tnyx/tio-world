import '../models/models.dart';

/// Pure use case to construct the flattened, continuous [OnboardingProgressPlan]
/// dynamically derived from the active [OnboardingFlowPlan] and [WorkoutFlowPlan].
class BuildOnboardingProgressPlanUseCase {
  const BuildOnboardingProgressPlanUseCase();

  OnboardingProgressPlan call({
    required OnboardingFlowPlan flowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
  }) {
    final items = <OnboardingProgressItem>[];

    for (final step in flowPlan.steps) {
      switch (step.id) {
        case OnboardingStepId.mode:
          // AppMode is a pre-progress screen — excluded from visible progress denominator.
          break;

        case OnboardingStepId.profileBasics:
          for (final profileStep in ProfileStepId.values) {
            items.add(ProfileProgressItem(profileStep));
          }
          break;

        case OnboardingStepId.mobile:
          items.add(const MobileProgressItem());
          break;

        case OnboardingStepId.workoutIntro:
          items.add(const WorkoutIntroProgressItem());
          break;

        case OnboardingStepId.workoutPreferences:
          for (final workoutStep in workoutFlowPlan.steps) {
            items.add(WorkoutProgressItem(workoutStep));
          }
          break;

        case OnboardingStepId.nutritionIntro:
          items.add(const NutritionIntroProgressItem());
          break;

        case OnboardingStepId.nutritionPreferences:
          items.add(const NutritionPreferencesProgressItem());
          break;

        case OnboardingStepId.targets:
          for (final targetStep in TargetsFlowPlan.orderedSteps) {
            items.add(TargetsProgressItem(targetStep));
          }
          break;

        case OnboardingStepId.review:
          items.add(const ReviewProgressItem());
          break;

        case OnboardingStepId.userProfile:
        case OnboardingStepId.bodyGoal:
        case OnboardingStepId.wellnessGoals:
        case OnboardingStepId.nutritionProfile:
        case OnboardingStepId.workoutProfile:
        case OnboardingStepId.nutritionGoals:
        case OnboardingStepId.workoutTargets:
        case OnboardingStepId.healthConnections:
        case OnboardingStepId.planBuilding:
          throw StateError(
            'Future onboarding step ${step.id.name} is not active in Slice 1.',
          );
      }
    }

    return OnboardingProgressPlan(items: List.unmodifiable(items));
  }
}

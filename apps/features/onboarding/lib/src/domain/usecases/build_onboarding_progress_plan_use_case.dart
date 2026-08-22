import '../models/models.dart';

/// Pure use case to construct the flattened, continuous [OnboardingProgressPlan]
/// dynamically derived from the active nested flow plans.
class BuildOnboardingProgressPlanUseCase {
  const BuildOnboardingProgressPlanUseCase();

  OnboardingProgressPlan call({
    required OnboardingFlowPlan flowPlan,
    required WorkoutFlowPlan workoutFlowPlan,
    ProfileFlowPlan profileFlowPlan = const ProfileFlowPlan(),
    BodyGoalFlowPlan bodyGoalFlowPlan = const BodyGoalFlowPlan(),
    WellnessFlowPlan wellnessFlowPlan = const WellnessFlowPlan(),
    TargetsFlowPlan targetsFlowPlan = const TargetsFlowPlan(),
  }) {
    final items = <OnboardingProgressItem>[];

    for (final step in flowPlan.steps) {
      switch (step.id) {
        case OnboardingStepId.mode:
          // AppMode is a pre-progress screen — excluded from visible progress denominator.
          break;

        case OnboardingStepId.profileBasics:
          for (final profileStep in profileFlowPlan.steps) {
            items.add(ProfileProgressItem(profileStep));
          }
          break;

        case OnboardingStepId.bodyGoal:
          for (final bodyGoalStep in bodyGoalFlowPlan.steps) {
            items.add(BodyGoalProgressItem(bodyGoalStep));
          }
          break;

        case OnboardingStepId.wellnessGoals:
          for (final wellnessStep in wellnessFlowPlan.steps) {
            items.add(WellnessProgressItem(wellnessStep));
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
          for (final targetStep in targetsFlowPlan.steps) {
            items.add(TargetsProgressItem(targetStep));
          }
          break;

        case OnboardingStepId.review:
          items.add(const ReviewProgressItem());
          break;

        case OnboardingStepId.userProfile:
        case OnboardingStepId.nutritionProfile:
        case OnboardingStepId.workoutProfile:
        case OnboardingStepId.nutritionGoals:
        case OnboardingStepId.workoutTargets:
        case OnboardingStepId.healthConnections:
        case OnboardingStepId.planBuilding:
          throw StateError(
            'Future onboarding step ${step.id.name} is not active in the current flow.',
          );
      }
    }

    return OnboardingProgressPlan(items: List.unmodifiable(items));
  }
}

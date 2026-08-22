import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const buildFlow = BuildOnboardingFlowUseCase();

  group('BuildOnboardingFlowUseCase', () {
    test('retains legacy mode-only compatibility when no mode is seeded', () {
      final plan = buildFlow(entryPath: OnboardingEntryPath.firstRun);
      expect(plan.stepIds, const [OnboardingStepId.mode]);
    });

    test('active common sections use canonical section identities', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
      );
      expect(
        plan.definitionFor(OnboardingStepId.profileBasics).section,
        OnboardingSectionId.userProfile,
      );
      expect(
        plan.definitionFor(OnboardingStepId.bodyGoal).section,
        OnboardingSectionId.bodyGoal,
      );
      expect(
        plan.definitionFor(OnboardingStepId.wellnessGoals).section,
        OnboardingSectionId.wellnessGoals,
      );
      expect(
        plan.definitionFor(OnboardingStepId.nutritionProfile).section,
        OnboardingSectionId.nutritionProfile,
      );
    });

    test('workout mode excludes Nutrition Profile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        includeMobile: true,
      );
      expect(
        plan.stepIds,
        const [
          OnboardingStepId.profileBasics,
          OnboardingStepId.bodyGoal,
          OnboardingStepId.wellnessGoals,
          OnboardingStepId.workoutPreferences,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
      expect(plan.stepIds, isNot(contains(OnboardingStepId.nutritionProfile)));
    });

    test('nutrition mode inserts Nutrition Profile after Wellness', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.resumeDraft,
        mode: AppMode.nutrition,
        includeMobile: true,
      );
      expect(
        plan.stepIds,
        const [
          OnboardingStepId.profileBasics,
          OnboardingStepId.bodyGoal,
          OnboardingStepId.wellnessGoals,
          OnboardingStepId.nutritionProfile,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });

    test('hybrid inserts Nutrition Profile before Workout setup', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        includeMobile: true,
      );
      expect(
        plan.stepIds,
        const [
          OnboardingStepId.profileBasics,
          OnboardingStepId.bodyGoal,
          OnboardingStepId.wellnessGoals,
          OnboardingStepId.nutritionProfile,
          OnboardingStepId.workoutIntro,
          OnboardingStepId.workoutPreferences,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });

    test('hybrid later keeps Nutrition Profile and skips Workout preferences', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );
      expect(
        plan.stepIds,
        const [
          OnboardingStepId.profileBasics,
          OnboardingStepId.bodyGoal,
          OnboardingStepId.wellnessGoals,
          OnboardingStepId.nutritionProfile,
          OnboardingStepId.workoutIntro,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });

    test('active sections contain no account-setup mobile section', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        includeMobile: true,
      );
      expect(
        plan.steps.map((step) => step.section),
        isNot(contains(OnboardingSectionId.mobile)),
      );
    });
  });

  group('reconciliation', () {
    test('keeps current eligible step after mode change', () {
      final workoutPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final hybridPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
      );
      expect(
        buildFlow.reconcileCurrentStep(
          currentStepId: OnboardingStepId.targets,
          previousPlan: workoutPlan,
          nextPlan: hybridPlan,
        ),
        OnboardingStepId.targets,
      );
    });

    test('hiding Nutrition Profile falls back to Wellness', () {
      final nutritionPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
      );
      final workoutPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      expect(
        buildFlow.reconcileCurrentStep(
          currentStepId: OnboardingStepId.nutritionProfile,
          previousPlan: nutritionPlan,
          nextPlan: workoutPlan,
        ),
        OnboardingStepId.wellnessGoals,
      );
    });
  });
}

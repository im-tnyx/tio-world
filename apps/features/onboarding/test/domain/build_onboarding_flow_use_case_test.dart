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
      expect(
        plan.definitionFor(OnboardingStepId.nutritionGoals).section,
        OnboardingSectionId.nutritionGoals,
      );
      expect(
        plan.definitionFor(OnboardingStepId.healthConnections).section,
        OnboardingSectionId.healthConnections,
      );
      expect(
        plan.definitionFor(OnboardingStepId.healthConnections).isRequired,
        isFalse,
      );
    });

    test('workout mode activates canonical Profile then Targets', () {
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
          OnboardingStepId.workoutProfile,
          OnboardingStepId.workoutTargets,
          OnboardingStepId.nutritionGoals,
          OnboardingStepId.healthConnections,
          OnboardingStepId.review,
        ],
      );
      expect(
        plan.definitionFor(OnboardingStepId.workoutProfile).section,
        OnboardingSectionId.workoutProfile,
      );
      expect(
        plan.definitionFor(OnboardingStepId.workoutTargets).section,
        OnboardingSectionId.workoutTargets,
      );
      expect(plan.stepIds, isNot(contains(OnboardingStepId.nutritionProfile)));
      expect(plan.stepIds, isNot(contains(OnboardingStepId.targets)));
    });

    test('nutrition mode inserts Nutrition Profile then Nutrition Goals', () {
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
          OnboardingStepId.nutritionGoals,
          OnboardingStepId.healthConnections,
          OnboardingStepId.review,
        ],
      );
      expect(plan.stepIds, isNot(contains(OnboardingStepId.workoutProfile)));
      expect(plan.stepIds, isNot(contains(OnboardingStepId.workoutTargets)));
    });

    test('hybrid setup now inserts canonical Workout owner sections', () {
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
          OnboardingStepId.workoutProfile,
          OnboardingStepId.workoutTargets,
          OnboardingStepId.nutritionGoals,
          OnboardingStepId.healthConnections,
          OnboardingStepId.review,
        ],
      );
    });

    test('hybrid later keeps Nutrition and skips both Workout sections', () {
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
          OnboardingStepId.nutritionGoals,
          OnboardingStepId.healthConnections,
          OnboardingStepId.review,
        ],
      );
      expect(plan.stepIds, isNot(contains(OnboardingStepId.workoutProfile)));
      expect(plan.stepIds, isNot(contains(OnboardingStepId.workoutTargets)));
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
    test('keeps current eligible Nutrition Goals after mode change', () {
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
          currentStepId: OnboardingStepId.nutritionGoals,
          previousPlan: workoutPlan,
          nextPlan: hybridPlan,
        ),
        OnboardingStepId.nutritionGoals,
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

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

    test('active profileBasics step uses canonical userProfile section identity',
        () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );

      expect(
        plan.definitionFor(OnboardingStepId.profileBasics).section,
        OnboardingSectionId.userProfile,
      );
      expect(
        plan.steps.map((step) => step.section),
        isNot(contains(OnboardingSectionId.profile)),
      );
    });

    test('workout product onboarding starts at profile and never includes mobile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        includeMobile: true,
      );
      expect(
        plan.stepIds,
        const [
          OnboardingStepId.profileBasics,
          OnboardingStepId.workoutPreferences,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
      expect(plan.stepIds, isNot(contains(OnboardingStepId.mode)));
      expect(plan.stepIds, isNot(contains(OnboardingStepId.mobile)));
    });

    test('nutrition product onboarding starts at profile and never includes mobile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.resumeDraft,
        mode: AppMode.nutrition,
        includeMobile: true,
      );
      expect(
        plan.stepIds,
        const [
          OnboardingStepId.profileBasics,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
      expect(plan.stepIds, isNot(contains(OnboardingStepId.mode)));
    });

    test('hybrid product onboarding starts at profile and never includes mobile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        includeMobile: true,
      );
      expect(
        plan.stepIds,
        const [
          OnboardingStepId.profileBasics,
          OnboardingStepId.workoutIntro,
          OnboardingStepId.workoutPreferences,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
      expect(plan.stepIds, isNot(contains(OnboardingStepId.mode)));
    });

    test('hybrid later still skips workout preferences', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );
      expect(
        plan.stepIds,
        const [
          OnboardingStepId.profileBasics,
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

    test('falls back to nearest previous eligible step', () {
      final hybridPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
      );
      final workoutPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );

      expect(
        buildFlow.reconcileCurrentStep(
          currentStepId: OnboardingStepId.workoutIntro,
          previousPlan: hybridPlan,
          nextPlan: workoutPlan,
        ),
        OnboardingStepId.profileBasics,
      );
    });
  });
}

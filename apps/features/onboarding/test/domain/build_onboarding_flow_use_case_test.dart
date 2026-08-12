import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const buildFlow = BuildOnboardingFlowUseCase();

  test('builds only the mode step before a mode is selected', () {
    final plan = buildFlow(entryPath: OnboardingEntryPath.firstRun);

    expect(plan.mode, isNull);
    expect(plan.stepIds, const [OnboardingStepId.mode]);
  });

  test('builds the exact workout flow', () {
    final plan = buildFlow(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.workout,
    );

    expect(
      plan.stepIds,
      const [
        OnboardingStepId.mode,
        OnboardingStepId.profileBasics,
        OnboardingStepId.workoutIntro,
        OnboardingStepId.workoutPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
    );
  });

  test('builds the exact nutrition flow', () {
    final plan = buildFlow(
      entryPath: OnboardingEntryPath.resumeDraft,
      mode: AppMode.nutrition,
    );

    expect(
      plan.stepIds,
      const [
        OnboardingStepId.mode,
        OnboardingStepId.profileBasics,
        OnboardingStepId.nutritionIntro,
        OnboardingStepId.nutritionPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
    );
  });

  test('builds the exact hybrid flow', () {
    final plan = buildFlow(
      entryPath: OnboardingEntryPath.legacyModeOnly,
      mode: AppMode.hybrid,
    );

    expect(
      plan.stepIds,
      const [
        OnboardingStepId.mode,
        OnboardingStepId.profileBasics,
        OnboardingStepId.workoutIntro,
        OnboardingStepId.workoutPreferences,
        OnboardingStepId.nutritionIntro,
        OnboardingStepId.nutritionPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
    );
  });

  test('keeps a current step that remains eligible after a mode change', () {
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

  test('falls back to the nearest previous eligible stable step', () {
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
        currentStepId: OnboardingStepId.nutritionPreferences,
        previousPlan: hybridPlan,
        nextPlan: workoutPlan,
      ),
      OnboardingStepId.workoutPreferences,
    );
  });
}

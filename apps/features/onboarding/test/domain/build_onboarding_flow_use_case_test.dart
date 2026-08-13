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

  test('skips workout preferences when hybrid defers workout setup', () {
    final plan = buildFlow(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.hybrid,
      workoutIntroChoice: WorkoutIntroChoice.later,
    );

    expect(
      plan.stepIds,
      const [
        OnboardingStepId.mode,
        OnboardingStepId.profileBasics,
        OnboardingStepId.workoutIntro,
        OnboardingStepId.nutritionIntro,
        OnboardingStepId.nutritionPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
    );
  });

  test('maps every active step to its typed section', () {
    final plan = buildFlow(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.hybrid,
    );

    expect(
      {
        for (final definition in plan.steps) definition.id: definition.section,
      },
      const {
        OnboardingStepId.mode: OnboardingSectionId.appMode,
        OnboardingStepId.profileBasics: OnboardingSectionId.profile,
        OnboardingStepId.workoutIntro: OnboardingSectionId.workoutIntro,
        OnboardingStepId.workoutPreferences: OnboardingSectionId.workout,
        OnboardingStepId.nutritionIntro: OnboardingSectionId.nutritionIntro,
        OnboardingStepId.nutritionPreferences: OnboardingSectionId.nutrition,
        OnboardingStepId.targets: OnboardingSectionId.targets,
        OnboardingStepId.review: OnboardingSectionId.review,
      },
    );
  });

  test('does not duplicate shared steps in any mode plan', () {
    for (final mode in AppMode.values) {
      final stepIds = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: mode,
      ).stepIds;

      expect(stepIds.toSet(), hasLength(stepIds.length), reason: mode.name);
      expect(
        stepIds.where((step) => step == OnboardingStepId.profileBasics),
        hasLength(1),
        reason: mode.name,
      );
      expect(
        stepIds.where((step) => step == OnboardingStepId.targets),
        hasLength(1),
        reason: mode.name,
      );
      expect(
        stepIds.where((step) => step == OnboardingStepId.review),
        hasLength(1),
        reason: mode.name,
      );
    }
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

  test('reconciles removed workout preferences back to workout intro', () {
    final hybridPlan = buildFlow(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.hybrid,
    );
    final hybridLaterPlan = buildFlow(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.hybrid,
      workoutIntroChoice: WorkoutIntroChoice.later,
    );

    expect(
      buildFlow.reconcileCurrentStep(
        currentStepId: OnboardingStepId.workoutPreferences,
        previousPlan: hybridPlan,
        nextPlan: hybridLaterPlan,
      ),
      OnboardingStepId.workoutIntro,
    );
  });
}

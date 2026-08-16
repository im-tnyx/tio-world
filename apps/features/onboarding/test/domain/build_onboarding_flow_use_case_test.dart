import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const buildFlow = BuildOnboardingFlowUseCase();

  group('BuildOnboardingFlowUseCase - Case A (includeMobile: false)', () {
    test('builds only the mode step before a mode is selected', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        includeMobile: false,
      );

      expect(plan.mode, isNull);
      expect(plan.stepIds, const [OnboardingStepId.mode]);
    });

    test('builds the exact workout flow without mobile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        includeMobile: false,
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

    test('builds the exact nutrition flow without mobile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.resumeDraft,
        mode: AppMode.nutrition,
        includeMobile: false,
      );

      expect(
        plan.stepIds,
        const [
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });

    test('builds the exact hybrid flow without mobile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.legacyModeOnly,
        mode: AppMode.hybrid,
        includeMobile: false,
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

    test('skips workout preferences when hybrid defers workout setup without mobile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        includeMobile: false,
      );

      expect(
        plan.stepIds,
        const [
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
          OnboardingStepId.workoutIntro,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });
  });

  group('BuildOnboardingFlowUseCase - Case B (includeMobile: true)', () {
    test('builds the exact workout flow with mobile section', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        includeMobile: true,
      );

      expect(
        plan.stepIds,
        const [
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
          OnboardingStepId.mobile,
          OnboardingStepId.workoutPreferences,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });

    test('builds the exact nutrition flow with mobile section', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.resumeDraft,
        mode: AppMode.nutrition,
        includeMobile: true,
      );

      expect(
        plan.stepIds,
        const [
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
          OnboardingStepId.mobile,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });

    test('builds the exact hybrid flow with mobile section', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.legacyModeOnly,
        mode: AppMode.hybrid,
        includeMobile: true,
      );

      expect(
        plan.stepIds,
        const [
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
          OnboardingStepId.mobile,
          OnboardingStepId.workoutIntro,
          OnboardingStepId.workoutPreferences,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });

    test('skips workout preferences when hybrid defers workout setup with mobile', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        includeMobile: true,
      );

      expect(
        plan.stepIds,
        const [
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
          OnboardingStepId.mobile,
          OnboardingStepId.workoutIntro,
          OnboardingStepId.targets,
          OnboardingStepId.review,
        ],
      );
    });
  });

  group('BuildOnboardingFlowUseCase - Sections & Reconciliation', () {
    test('maps every active step to its typed section', () {
      final plan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        includeMobile: true,
      );

      expect(
        {
          for (final definition in plan.steps) definition.id: definition.section,
        },
        const {
          OnboardingStepId.mode: OnboardingSectionId.appMode,
          OnboardingStepId.profileBasics: OnboardingSectionId.profile,
          OnboardingStepId.mobile: OnboardingSectionId.mobile,
          OnboardingStepId.workoutIntro: OnboardingSectionId.workoutIntro,
          OnboardingStepId.workoutPreferences: OnboardingSectionId.workout,
          OnboardingStepId.targets: OnboardingSectionId.targets,
          OnboardingStepId.review: OnboardingSectionId.review,
        },
      );
    });

    test('does not duplicate shared steps in any mode plan', () {
      for (final mode in AppMode.values) {
        for (final includeMobile in [false, true]) {
          final stepIds = buildFlow(
            entryPath: OnboardingEntryPath.firstRun,
            mode: mode,
            includeMobile: includeMobile,
          ).stepIds;

          expect(stepIds.toSet(), hasLength(stepIds.length), reason: '${mode.name} (mobile: $includeMobile)');
          expect(
            stepIds.where((step) => step == OnboardingStepId.profileBasics),
            hasLength(1),
            reason: '${mode.name} (mobile: $includeMobile)',
          );
          expect(
            stepIds.where((step) => step == OnboardingStepId.targets),
            hasLength(1),
            reason: '${mode.name} (mobile: $includeMobile)',
          );
          expect(
            stepIds.where((step) => step == OnboardingStepId.review),
            hasLength(1),
            reason: '${mode.name} (mobile: $includeMobile)',
          );
        }
      }
    });

    test('keeps a current step that remains eligible after a mode change', () {
      final workoutPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        includeMobile: false,
      );
      final hybridPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        includeMobile: false,
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
        includeMobile: false,
      );
      final workoutPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        includeMobile: false,
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

    test('reconciles removed workout preferences back to workout intro', () {
      final hybridPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        includeMobile: false,
      );
      final hybridLaterPlan = buildFlow(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        includeMobile: false,
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
  });
}

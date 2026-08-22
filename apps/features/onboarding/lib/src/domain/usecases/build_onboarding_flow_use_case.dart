import 'package:tio_shared/shared.dart';

import '../models/models.dart';

class BuildOnboardingFlowUseCase {
  const BuildOnboardingFlowUseCase();

  OnboardingFlowPlan call({
    required OnboardingEntryPath entryPath,
    AppMode? mode,
    WorkoutIntroChoice? workoutIntroChoice,
    @Deprecated('Mobile belongs to Account Setup and is never included here.')
    bool includeMobile = false,
  }) {
    return OnboardingFlowPlan(
      entryPath: entryPath,
      mode: mode,
      // A null mode is retained only as a legacy compatibility state so old
      // drafts/tests can reconcile through the former mode step. Current app
      // routing always seeds a selected mode before Product Onboarding.
      steps: mode == null
          ? const [_legacyMode]
          : _stepsByMode(
              mode,
              workoutIntroChoice: workoutIntroChoice,
            ),
    );
  }

  OnboardingStepId reconcileCurrentStep({
    required OnboardingStepId currentStepId,
    required OnboardingFlowPlan previousPlan,
    required OnboardingFlowPlan nextPlan,
  }) {
    if (nextPlan.contains(currentStepId)) return currentStepId;

    final previousIndex = previousPlan.indexOf(currentStepId);
    for (var index = previousIndex - 1; index >= 0; index--) {
      final candidate = previousPlan.steps[index].id;
      if (nextPlan.contains(candidate)) return candidate;
    }

    return nextPlan.steps.first.id;
  }
}

List<OnboardingStepDefinition> _stepsByMode(
  AppMode mode, {
  WorkoutIntroChoice? workoutIntroChoice,
}) {
  const profileAndBody = <OnboardingStepDefinition>[
    _profileBasics,
    _bodyGoal,
  ];

  return switch (mode) {
    AppMode.workout => [
        ...profileAndBody,
        _workoutPreferences,
        _targets,
        _review,
      ],
    AppMode.nutrition => [
        ...profileAndBody,
        _targets,
        _review,
      ],
    AppMode.hybrid => workoutIntroChoice == WorkoutIntroChoice.later
        ? [
            ...profileAndBody,
            _workoutIntro,
            _targets,
            _review,
          ]
        : [
            ...profileAndBody,
            _workoutIntro,
            _workoutPreferences,
            _targets,
            _review,
          ],
  };
}

const _legacyMode = OnboardingStepDefinition(
  id: OnboardingStepId.mode,
  section: OnboardingSectionId.appMode,
  owner: OnboardingStepOwner.onboarding,
  progressTitle: 'Choose mode',
);
const _profileBasics = OnboardingStepDefinition(
  id: OnboardingStepId.profileBasics,
  section: OnboardingSectionId.userProfile,
  owner: OnboardingStepOwner.profile,
  progressTitle: 'About you',
);
const _bodyGoal = OnboardingStepDefinition(
  id: OnboardingStepId.bodyGoal,
  section: OnboardingSectionId.bodyGoal,
  owner: OnboardingStepOwner.crossFeature,
  progressTitle: 'Body goal',
);
const _workoutIntro = OnboardingStepDefinition(
  id: OnboardingStepId.workoutIntro,
  section: OnboardingSectionId.workoutIntro,
  owner: OnboardingStepOwner.workout,
  progressTitle: 'Workout setup',
);
const _workoutPreferences = OnboardingStepDefinition(
  id: OnboardingStepId.workoutPreferences,
  section: OnboardingSectionId.workout,
  owner: OnboardingStepOwner.workout,
  progressTitle: 'Training preferences',
);
const _targets = OnboardingStepDefinition(
  id: OnboardingStepId.targets,
  section: OnboardingSectionId.targets,
  owner: OnboardingStepOwner.crossFeature,
  progressTitle: 'Your targets',
);
const _review = OnboardingStepDefinition(
  id: OnboardingStepId.review,
  section: OnboardingSectionId.review,
  owner: OnboardingStepOwner.onboarding,
  progressTitle: 'Review setup',
);

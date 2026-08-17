import 'package:tio_shared/shared.dart';

import '../models/models.dart';

class BuildOnboardingFlowUseCase {
  const BuildOnboardingFlowUseCase();

  OnboardingFlowPlan call({
    required OnboardingEntryPath entryPath,
    AppMode? mode,
    WorkoutIntroChoice? workoutIntroChoice,
    bool includeMobile = true,
  }) {
    return OnboardingFlowPlan(
      entryPath: entryPath,
      mode: mode,
      steps: mode == null
          ? const [_mode]
          : _stepsByMode(
              mode,
              workoutIntroChoice: workoutIntroChoice,
              includeMobile: includeMobile,
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
  bool includeMobile = true,
}) {
  final profileAndMobile = <OnboardingStepDefinition>[
    _profileBasics,
    if (includeMobile) _mobile,
  ];

  return switch (mode) {
    AppMode.workout => [
        _mode,
        ...profileAndMobile,
        _workoutPreferences,
        _targets,
        _review,
      ],
    AppMode.nutrition => [
        _mode,
        ...profileAndMobile,
        _targets,
        _review,
      ],
    AppMode.hybrid => workoutIntroChoice == WorkoutIntroChoice.later
        ? [
            _mode,
            ...profileAndMobile,
            _workoutIntro,
            _targets,
            _review,
          ]
        : [
            _mode,
            ...profileAndMobile,
            _workoutIntro,
            _workoutPreferences,
            _targets,
            _review,
          ],
  };
}

const _mode = OnboardingStepDefinition(
  id: OnboardingStepId.mode,
  section: OnboardingSectionId.appMode,
  owner: OnboardingStepOwner.onboarding,
  progressTitle: 'Choose mode',
);
const _profileBasics = OnboardingStepDefinition(
  id: OnboardingStepId.profileBasics,
  section: OnboardingSectionId.profile,
  owner: OnboardingStepOwner.profile,
  progressTitle: 'About you',
);
const _mobile = OnboardingStepDefinition(
  id: OnboardingStepId.mobile,
  section: OnboardingSectionId.mobile,
  owner: OnboardingStepOwner.profile,
  progressTitle: 'Mobile (optional)',
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

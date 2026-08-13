import 'package:tio_shared/shared.dart';

import '../models/models.dart';

class BuildOnboardingFlowUseCase {
  const BuildOnboardingFlowUseCase();

  OnboardingFlowPlan call({
    required OnboardingEntryPath entryPath,
    AppMode? mode,
    WorkoutIntroChoice? workoutIntroChoice,
  }) {
    return OnboardingFlowPlan(
      entryPath: entryPath,
      mode: mode,
      steps: mode == null
          ? const [_mode]
          : _stepsByMode(mode, workoutIntroChoice: workoutIntroChoice),
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
  return switch (mode) {
    AppMode.workout => const [
        _mode,
        _profileBasics,
        _workoutPreferences,
        _targets,
        _review,
      ],
    AppMode.nutrition => const [
        _mode,
        _profileBasics,
        _nutritionIntro,
        _nutritionPreferences,
        _targets,
        _review,
      ],
    AppMode.hybrid => workoutIntroChoice == WorkoutIntroChoice.later
        ? const [
            _mode,
            _profileBasics,
            _workoutIntro,
            _nutritionIntro,
            _nutritionPreferences,
            _targets,
            _review,
          ]
        : const [
            _mode,
            _profileBasics,
            _workoutIntro,
            _workoutPreferences,
            _nutritionIntro,
            _nutritionPreferences,
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
const _nutritionIntro = OnboardingStepDefinition(
  id: OnboardingStepId.nutritionIntro,
  section: OnboardingSectionId.nutritionIntro,
  owner: OnboardingStepOwner.nutrition,
  progressTitle: 'Nutrition setup',
);
const _nutritionPreferences = OnboardingStepDefinition(
  id: OnboardingStepId.nutritionPreferences,
  section: OnboardingSectionId.nutrition,
  owner: OnboardingStepOwner.nutrition,
  progressTitle: 'Nutrition preferences',
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

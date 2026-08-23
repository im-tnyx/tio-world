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

  /// Reconciles a persisted top-level step from older flow policies.
  ///
  /// Persisted resume differs from a live mode switch: when the current section
  /// was deliberately removed from the selected mode, resume advances to the
  /// first still-eligible section that followed it in the old flow. This avoids
  /// forcing the user to repeat already completed setup.
  OnboardingStepId reconcilePersistedCurrentStep({
    required OnboardingStepId currentStepId,
    required OnboardingEntryPath entryPath,
    required AppMode? mode,
    WorkoutIntroChoice? workoutIntroChoice,
  }) {
    final nextPlan = call(
      entryPath: entryPath,
      mode: mode,
      workoutIntroChoice: workoutIntroChoice,
    );
    if (nextPlan.contains(currentStepId) || mode == null) {
      return nextPlan.contains(currentStepId)
          ? currentStepId
          : nextPlan.steps.first.id;
    }

    // Older drafts used one monolithic Targets top-level checkpoint. Preserve
    // forward progress while mapping it to the closest current mode boundary.
    if (currentStepId == OnboardingStepId.targets) {
      return switch (mode) {
        AppMode.workout => OnboardingStepId.healthConnections,
        AppMode.nutrition || AppMode.hybrid => OnboardingStepId.wellnessGoals,
      };
    }

    final previousPlan = OnboardingFlowPlan(
      entryPath: entryPath,
      mode: mode,
      steps: _legacyPreModeSpecificStepsByMode(
        mode,
        workoutIntroChoice: workoutIntroChoice,
      ),
    );
    final previousIndex = previousPlan.indexOf(currentStepId);
    if (previousIndex >= 0) {
      for (var index = previousIndex + 1;
          index < previousPlan.steps.length;
          index++) {
        final candidate = previousPlan.steps[index].id;
        if (nextPlan.contains(candidate)) return candidate;
      }
      for (var index = previousIndex - 1; index >= 0; index--) {
        final candidate = previousPlan.steps[index].id;
        if (nextPlan.contains(candidate)) return candidate;
      }
    }

    return nextPlan.steps.first.id;
  }
}

List<OnboardingStepDefinition> _stepsByMode(
  AppMode mode, {
  WorkoutIntroChoice? workoutIntroChoice,
}) {
  const commonFoundation = <OnboardingStepDefinition>[
    _profileBasics,
    _bodyGoal,
  ];

  return switch (mode) {
    AppMode.workout => [
        ...commonFoundation,
        _workoutProfile,
        _workoutTargets,
        _healthConnections,
        _review,
      ],
    AppMode.nutrition => [
        ...commonFoundation,
        _nutritionProfile,
        _wellnessGoals,
        _nutritionGoals,
        _healthConnections,
        _review,
      ],
    AppMode.hybrid => workoutIntroChoice == WorkoutIntroChoice.later
        ? [
            ...commonFoundation,
            _nutritionProfile,
            _workoutIntro,
            _wellnessGoals,
            _nutritionGoals,
            _healthConnections,
            _review,
          ]
        : [
            ...commonFoundation,
            _nutritionProfile,
            _workoutIntro,
            _workoutProfile,
            _workoutTargets,
            _wellnessGoals,
            _nutritionGoals,
            _healthConnections,
            _review,
          ],
  };
}

List<OnboardingStepDefinition> _legacyPreModeSpecificStepsByMode(
  AppMode mode, {
  WorkoutIntroChoice? workoutIntroChoice,
}) {
  const commonFoundation = <OnboardingStepDefinition>[
    _profileBasics,
    _bodyGoal,
    _wellnessGoals,
  ];

  return switch (mode) {
    AppMode.workout => [
        ...commonFoundation,
        _workoutProfile,
        _workoutTargets,
        _nutritionGoals,
        _healthConnections,
        _review,
      ],
    AppMode.nutrition => [
        ...commonFoundation,
        _nutritionProfile,
        _nutritionGoals,
        _healthConnections,
        _review,
      ],
    AppMode.hybrid => workoutIntroChoice == WorkoutIntroChoice.later
        ? [
            ...commonFoundation,
            _nutritionProfile,
            _workoutIntro,
            _nutritionGoals,
            _healthConnections,
            _review,
          ]
        : [
            ...commonFoundation,
            _nutritionProfile,
            _workoutIntro,
            _workoutProfile,
            _workoutTargets,
            _nutritionGoals,
            _healthConnections,
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
const _wellnessGoals = OnboardingStepDefinition(
  id: OnboardingStepId.wellnessGoals,
  section: OnboardingSectionId.wellnessGoals,
  owner: OnboardingStepOwner.crossFeature,
  progressTitle: 'Wellness',
);
const _nutritionProfile = OnboardingStepDefinition(
  id: OnboardingStepId.nutritionProfile,
  section: OnboardingSectionId.nutritionProfile,
  owner: OnboardingStepOwner.nutrition,
  progressTitle: 'Nutrition profile',
);
const _workoutIntro = OnboardingStepDefinition(
  id: OnboardingStepId.workoutIntro,
  section: OnboardingSectionId.workoutIntro,
  owner: OnboardingStepOwner.workout,
  progressTitle: 'Workout setup',
);
const _workoutProfile = OnboardingStepDefinition(
  id: OnboardingStepId.workoutProfile,
  section: OnboardingSectionId.workoutProfile,
  owner: OnboardingStepOwner.workout,
  progressTitle: 'Training preferences',
);
const _workoutTargets = OnboardingStepDefinition(
  id: OnboardingStepId.workoutTargets,
  section: OnboardingSectionId.workoutTargets,
  owner: OnboardingStepOwner.workout,
  progressTitle: 'Workout targets',
);
const _nutritionGoals = OnboardingStepDefinition(
  id: OnboardingStepId.nutritionGoals,
  section: OnboardingSectionId.nutritionGoals,
  owner: OnboardingStepOwner.nutrition,
  progressTitle: 'Nutrition target',
);
const _healthConnections = OnboardingStepDefinition(
  id: OnboardingStepId.healthConnections,
  section: OnboardingSectionId.healthConnections,
  owner: OnboardingStepOwner.crossFeature,
  progressTitle: 'Health connections',
  isRequired: false,
);
const _review = OnboardingStepDefinition(
  id: OnboardingStepId.review,
  section: OnboardingSectionId.review,
  owner: OnboardingStepOwner.onboarding,
  progressTitle: 'Review setup',
);

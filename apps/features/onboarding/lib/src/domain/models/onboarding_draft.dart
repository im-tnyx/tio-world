import 'package:tio_shared/shared.dart';

import 'goal_intent.dart';
import 'onboarding_status.dart';
import 'onboarding_step_id.dart';
import 'nutrition_onboarding_draft.dart';
import 'profile_onboarding_draft.dart';
import 'targets_onboarding_draft.dart';
import 'workout_intro_choice.dart';
import 'workout_onboarding_draft.dart';

const _onboardingDraftUnchanged = Object();

class OnboardingDraft {
  OnboardingDraft({
    this.schemaVersion = currentSchemaVersion,
    this.status = OnboardingStatus.notStarted,
    this.selectedMode,
    this.workoutIntroChoice,
    this.goalSelection = const GoalIntentSelection(),
    this.currentStepId = OnboardingStepId.mode,
    ProfileOnboardingDraft? profile,
    NutritionOnboardingDraft? nutrition,
    WorkoutOnboardingDraft? workout,
    TargetsOnboardingDraft? targets,
    Set<OnboardingStepId> completedStepIds = const {},
  })  : profile = profile ?? ProfileOnboardingDraft(),
        nutrition = nutrition ?? const NutritionOnboardingDraft(),
        workout = workout ?? const WorkoutOnboardingDraft(),
        targets = targets ?? const TargetsOnboardingDraft(),
        completedStepIds = Set.unmodifiable(completedStepIds);

  static const currentSchemaVersion = 3;

  final int schemaVersion;
  final OnboardingStatus status;
  final AppMode? selectedMode;
  final WorkoutIntroChoice? workoutIntroChoice;
  final GoalIntentSelection goalSelection;
  final OnboardingStepId currentStepId;
  final ProfileOnboardingDraft profile;
  final NutritionOnboardingDraft nutrition;
  final WorkoutOnboardingDraft workout;
  final TargetsOnboardingDraft targets;
  final Set<OnboardingStepId> completedStepIds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OnboardingDraft &&
            schemaVersion == other.schemaVersion &&
            status == other.status &&
            selectedMode == other.selectedMode &&
            workoutIntroChoice == other.workoutIntroChoice &&
            goalSelection == other.goalSelection &&
            currentStepId == other.currentStepId &&
            profile == other.profile &&
            nutrition == other.nutrition &&
            workout == other.workout &&
            targets == other.targets &&
            completedStepIds.length == other.completedStepIds.length &&
            completedStepIds.every(other.completedStepIds.contains);
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        status,
        selectedMode,
        workoutIntroChoice,
        goalSelection,
        currentStepId,
        profile,
        nutrition,
        workout,
        targets,
        Object.hashAllUnordered(completedStepIds),
      );

  OnboardingDraft copyWith({
    int? schemaVersion,
    OnboardingStatus? status,
    Object? selectedMode = _onboardingDraftUnchanged,
    Object? workoutIntroChoice = _onboardingDraftUnchanged,
    GoalIntentSelection? goalSelection,
    OnboardingStepId? currentStepId,
    ProfileOnboardingDraft? profile,
    NutritionOnboardingDraft? nutrition,
    WorkoutOnboardingDraft? workout,
    TargetsOnboardingDraft? targets,
    Set<OnboardingStepId>? completedStepIds,
  }) {
    return OnboardingDraft(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      status: status ?? this.status,
      selectedMode: identical(selectedMode, _onboardingDraftUnchanged)
          ? this.selectedMode
          : selectedMode as AppMode?,
      workoutIntroChoice:
          identical(workoutIntroChoice, _onboardingDraftUnchanged)
              ? this.workoutIntroChoice
              : workoutIntroChoice as WorkoutIntroChoice?,
      goalSelection: goalSelection ?? this.goalSelection,
      currentStepId: currentStepId ?? this.currentStepId,
      profile: profile ?? this.profile,
      nutrition: nutrition ?? this.nutrition,
      workout: workout ?? this.workout,
      targets: targets ?? this.targets,
      completedStepIds: completedStepIds ?? this.completedStepIds,
    );
  }
}

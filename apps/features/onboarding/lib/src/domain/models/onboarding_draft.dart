import 'package:tio_shared/shared.dart';

import 'onboarding_status.dart';
import 'onboarding_step_id.dart';
import 'profile_onboarding_draft.dart';
import 'workout_intro_choice.dart';

const _onboardingDraftUnchanged = Object();

class OnboardingDraft {
  OnboardingDraft({
    this.schemaVersion = currentSchemaVersion,
    this.status = OnboardingStatus.notStarted,
    this.selectedMode,
    this.workoutIntroChoice,
    this.currentStepId = OnboardingStepId.mode,
    ProfileOnboardingDraft? profile,
    Set<OnboardingStepId> completedStepIds = const {},
  })  : profile = profile ?? ProfileOnboardingDraft(),
        completedStepIds = Set.unmodifiable(completedStepIds);

  static const currentSchemaVersion = 2;

  final int schemaVersion;
  final OnboardingStatus status;
  final AppMode? selectedMode;
  final WorkoutIntroChoice? workoutIntroChoice;
  final OnboardingStepId currentStepId;
  final ProfileOnboardingDraft profile;
  final Set<OnboardingStepId> completedStepIds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OnboardingDraft &&
            schemaVersion == other.schemaVersion &&
            status == other.status &&
            selectedMode == other.selectedMode &&
            workoutIntroChoice == other.workoutIntroChoice &&
            currentStepId == other.currentStepId &&
            profile == other.profile &&
            completedStepIds.length == other.completedStepIds.length &&
            completedStepIds.every(other.completedStepIds.contains);
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        status,
        selectedMode,
        workoutIntroChoice,
        currentStepId,
        profile,
        Object.hashAllUnordered(completedStepIds),
      );

  OnboardingDraft copyWith({
    int? schemaVersion,
    OnboardingStatus? status,
    Object? selectedMode = _onboardingDraftUnchanged,
    Object? workoutIntroChoice = _onboardingDraftUnchanged,
    OnboardingStepId? currentStepId,
    ProfileOnboardingDraft? profile,
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
      currentStepId: currentStepId ?? this.currentStepId,
      profile: profile ?? this.profile,
      completedStepIds: completedStepIds ?? this.completedStepIds,
    );
  }
}

import 'package:tio_shared/shared.dart';

import 'onboarding_status.dart';
import 'onboarding_step_id.dart';

class OnboardingDraft {
  OnboardingDraft({
    this.schemaVersion = currentSchemaVersion,
    this.status = OnboardingStatus.notStarted,
    this.selectedMode,
    this.currentStepId = OnboardingStepId.mode,
    Set<OnboardingStepId> completedStepIds = const {},
  }) : completedStepIds = Set.unmodifiable(completedStepIds);

  static const currentSchemaVersion = 1;

  final int schemaVersion;
  final OnboardingStatus status;
  final AppMode? selectedMode;
  final OnboardingStepId currentStepId;
  final Set<OnboardingStepId> completedStepIds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OnboardingDraft &&
            schemaVersion == other.schemaVersion &&
            status == other.status &&
            selectedMode == other.selectedMode &&
            currentStepId == other.currentStepId &&
            completedStepIds.length == other.completedStepIds.length &&
            completedStepIds.every(other.completedStepIds.contains);
  }

  @override
  int get hashCode => Object.hash(
        schemaVersion,
        status,
        selectedMode,
        currentStepId,
        Object.hashAllUnordered(completedStepIds),
      );

  OnboardingDraft copyWith({
    int? schemaVersion,
    OnboardingStatus? status,
    AppMode? selectedMode,
    OnboardingStepId? currentStepId,
    Set<OnboardingStepId>? completedStepIds,
  }) {
    return OnboardingDraft(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      status: status ?? this.status,
      selectedMode: selectedMode ?? this.selectedMode,
      currentStepId: currentStepId ?? this.currentStepId,
      completedStepIds: completedStepIds ?? this.completedStepIds,
    );
  }
}

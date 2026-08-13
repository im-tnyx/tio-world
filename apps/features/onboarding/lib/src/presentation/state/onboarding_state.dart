import '../../domain/domain.dart';

class OnboardingState {
  OnboardingState({
    required this.draft,
    required this.flowPlan,
    required this.stepId,
    Set<OnboardingStepId> completedStepIds = const {},
    Map<String, String> validationErrors = const {},
    this.isInitializing = false,
    this.isSaving = false,
    this.isCompleting = false,
    this.retryableError,
  })  : completedStepIds = Set.unmodifiable(completedStepIds),
        validationErrors = Map.unmodifiable(validationErrors);

  final OnboardingDraft draft;
  final OnboardingFlowPlan flowPlan;
  final OnboardingStepId stepId;
  final Set<OnboardingStepId> completedStepIds;
  final Map<String, String> validationErrors;
  final bool isInitializing;
  final bool isSaving;
  final bool isCompleting;
  final Object? retryableError;

  OnboardingStepDefinition get currentStep => flowPlan.definitionFor(stepId);
  OnboardingSectionId get currentSection => currentStep.section;
  int get currentIndex => flowPlan.indexOf(stepId);
  bool get isBusy => isInitializing || isSaving || isCompleting;
  bool get hasPreviousStep => currentIndex > 0;
  bool get canGoBack => hasPreviousStep && !isBusy;
  bool get canContinue =>
      !isBusy &&
      validationErrors.isEmpty &&
      switch (stepId) {
        OnboardingStepId.mode => draft.selectedMode != null,
        OnboardingStepId.workoutIntro => draft.workoutIntroChoice != null,
        _ => true,
      };

  String get primaryActionLabel {
    if (stepId == OnboardingStepId.review) return 'Finish';
    if (stepId == OnboardingStepId.targets) return 'Review';
    return 'Continue';
  }

  int get progressStepCount => flowPlan.steps.fold<int>(
        0,
        (total, step) => total + _progressWeight(step.id),
      );

  int get progressStepNumber {
    var position = 0;

    for (final step in flowPlan.steps.take(currentIndex + 1)) {
      if (step.id == OnboardingStepId.mode) continue;
      if (step.id == OnboardingStepId.profileBasics) {
        position += stepId == OnboardingStepId.profileBasics
            ? const ProfileFlowPlan().indexOf(
                  draft.profile.currentStepId,
                ) +
                1
            : ProfileFlowPlan.orderedSteps.length;
        continue;
      }
      position++;
    }

    return position;
  }

  double get progressValue {
    if (progressStepNumber == 0 || progressStepCount == 0) return 0;
    return progressStepNumber / progressStepCount;
  }

  String get progressSemantics {
    if (progressStepNumber == 0) return currentStep.progressTitle;
    return 'Step $progressStepNumber of $progressStepCount, '
        '${currentStep.progressTitle}';
  }

  static int _progressWeight(OnboardingStepId stepId) {
    return switch (stepId) {
      OnboardingStepId.mode => 0,
      OnboardingStepId.profileBasics => ProfileFlowPlan.orderedSteps.length,
      _ => 1,
    };
  }

  OnboardingState copyWith({
    OnboardingDraft? draft,
    OnboardingFlowPlan? flowPlan,
    OnboardingStepId? stepId,
    Set<OnboardingStepId>? completedStepIds,
    Map<String, String>? validationErrors,
    bool? isInitializing,
    bool? isSaving,
    bool? isCompleting,
    Object? retryableError,
    bool clearRetryableError = false,
  }) {
    return OnboardingState(
      draft: draft ?? this.draft,
      flowPlan: flowPlan ?? this.flowPlan,
      stepId: stepId ?? this.stepId,
      completedStepIds: completedStepIds ?? this.completedStepIds,
      validationErrors: validationErrors ?? this.validationErrors,
      isInitializing: isInitializing ?? this.isInitializing,
      isSaving: isSaving ?? this.isSaving,
      isCompleting: isCompleting ?? this.isCompleting,
      retryableError:
          clearRetryableError ? null : retryableError ?? this.retryableError,
    );
  }
}

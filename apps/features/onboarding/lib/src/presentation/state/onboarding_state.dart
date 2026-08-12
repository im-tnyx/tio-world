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
  int get currentIndex => flowPlan.indexOf(stepId);
  bool get isBusy => isInitializing || isSaving || isCompleting;
  bool get canGoBack => currentIndex > 0 && !isBusy;
  bool get canContinue =>
      !isBusy &&
      validationErrors.isEmpty &&
      (stepId != OnboardingStepId.mode || draft.selectedMode != null);

  String get primaryActionLabel {
    if (stepId == OnboardingStepId.review) return 'Finish';
    if (stepId == OnboardingStepId.targets) return 'Review';
    return 'Continue';
  }

  double get progressValue {
    if (draft.selectedMode == null) return 0;
    return (currentIndex + 1) / flowPlan.steps.length;
  }

  String get progressSemantics {
    if (draft.selectedMode == null) return currentStep.progressTitle;
    return 'Step ${currentIndex + 1} of ${flowPlan.steps.length}, '
        '${currentStep.progressTitle}';
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

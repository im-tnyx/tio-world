import '../../domain/domain.dart';

class OnboardingState {
  OnboardingState({
    required this.draft,
    required this.flowPlan,
    required this.workoutFlowPlan,
    required this.stepId,
    this.completionEligibility = OnboardingCompletionEligibility.eligible,
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
  final WorkoutFlowPlan workoutFlowPlan;
  final OnboardingStepId stepId;
  final OnboardingCompletionEligibility completionEligibility;
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

  ProfileFlowPlan get profileFlowPlan => const BuildProfileFlowPlanUseCase()(
        mode: draft.selectedMode,
        goalSelection: draft.goalSelection,
      );

  TargetsFlowPlan get targetsFlowPlan => const BuildTargetsFlowPlanUseCase()(
        mode: draft.selectedMode,
        goalSelection: draft.goalSelection,
      );

  GoalWeightDirection? get weightGoalDirection =>
      const WeightGoalFlowPolicy().directionFor(
        mode: draft.selectedMode,
        selection: draft.goalSelection,
      );

  /// Whether the current user-facing onboarding screen has an internal
  /// previous screen, including nested Profile, Workout, and Targets flows.
  ///
  /// [hasPreviousStep] intentionally remains the top-level flow-plan check for
  /// callers that specifically need section-level position.
  bool get hasPreviousScreen {
    if (stepId == OnboardingStepId.profileBasics &&
        profileFlowPlan.previous(draft.profile.currentStepId) != null) {
      return true;
    }

    if (stepId == OnboardingStepId.workoutPreferences &&
        workoutFlowPlan.indexOf(draft.workout.currentStepId) > 0) {
      return true;
    }

    if (stepId == OnboardingStepId.targets &&
        targetsFlowPlan.previous(draft.targets.currentStepId) != null) {
      return true;
    }

    return hasPreviousStep;
  }

  bool get hasPreviousStep => currentIndex > 0;
  bool get canGoBack => hasPreviousScreen && !isBusy;
  bool get canContinue =>
      !isBusy &&
      validationErrors.isEmpty &&
      switch (stepId) {
        OnboardingStepId.review => completionEligibility.isEligible,
        OnboardingStepId.mode => draft.selectedMode != null,
        OnboardingStepId.workoutIntro => draft.workoutIntroChoice != null,
        _ => true,
      };

  String get primaryActionLabel {
    if (stepId == OnboardingStepId.review) return 'Finish';
    if (stepId == OnboardingStepId.targets) {
      return targetsFlowPlan.primaryActionLabel(draft.targets.currentStepId);
    }
    return 'Continue';
  }

  OnboardingProgressPlan get progressPlan {
    return const BuildOnboardingProgressPlanUseCase()(
      flowPlan: flowPlan,
      profileFlowPlan: profileFlowPlan,
      workoutFlowPlan: workoutFlowPlan,
      targetsFlowPlan: targetsFlowPlan,
    );
  }

  int get progressStepCount {
    if (draft.selectedMode == null) return 0;
    return progressPlan.totalSteps;
  }

  int get progressStepNumber {
    if (draft.selectedMode == null || stepId == OnboardingStepId.mode) return 0;
    final index = progressPlan.indexOfCurrentScreen(
      stepId: stepId,
      profileStepId: draft.profile.currentStepId,
      workoutStepId: draft.workout.currentStepId,
      targetStepId: draft.targets.currentStepId,
    );
    return index < 0 ? 0 : index + 1;
  }

  double get progressValue {
    if (draft.selectedMode == null || stepId == OnboardingStepId.mode) return 0.0;
    return progressPlan.progressFor(
      stepId: stepId,
      profileStepId: draft.profile.currentStepId,
      workoutStepId: draft.workout.currentStepId,
      targetStepId: draft.targets.currentStepId,
    );
  }

  String get progressSemantics {
    if (progressStepNumber == 0) return currentStep.progressTitle;
    return 'Step $progressStepNumber of $progressStepCount, '
        '${currentStep.progressTitle}';
  }

  OnboardingState copyWith({
    OnboardingDraft? draft,
    OnboardingFlowPlan? flowPlan,
    WorkoutFlowPlan? workoutFlowPlan,
    OnboardingStepId? stepId,
    OnboardingCompletionEligibility? completionEligibility,
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
      workoutFlowPlan: workoutFlowPlan ?? this.workoutFlowPlan,
      stepId: stepId ?? this.stepId,
      completionEligibility:
          completionEligibility ?? this.completionEligibility,
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

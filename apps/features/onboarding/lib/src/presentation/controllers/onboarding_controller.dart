import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/domain.dart';
import '../state/state.dart';

class OnboardingControllerSeed {
  OnboardingControllerSeed({
    required this.entryPath,
    OnboardingDraft? draft,
  }) : draft = draft ?? OnboardingDraft();

  final OnboardingEntryPath entryPath;
  final OnboardingDraft draft;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OnboardingControllerSeed &&
            entryPath == other.entryPath &&
            draft == other.draft;
  }

  @override
  int get hashCode => Object.hash(entryPath, draft);
}

final onboardingControllerProvider = ChangeNotifierProvider.autoDispose
    .family<OnboardingController, OnboardingControllerSeed>((ref, seed) {
  return OnboardingController(
    entryPath: seed.entryPath,
    initialDraft: seed.draft,
  );
});

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required OnboardingEntryPath entryPath,
    OnboardingDraft? initialDraft,
    BuildOnboardingFlowUseCase planner = const BuildOnboardingFlowUseCase(),
  })  : _entryPath = entryPath,
        _planner = planner {
    _state = _buildInitialState(initialDraft ?? OnboardingDraft());
  }

  final OnboardingEntryPath _entryPath;
  final BuildOnboardingFlowUseCase _planner;

  late OnboardingState _state;

  OnboardingState get state => _state;

  OnboardingState _buildInitialState(OnboardingDraft draft) {
    final plan = _planner(entryPath: _entryPath, mode: draft.selectedMode);
    final stepId = plan.contains(draft.currentStepId)
        ? draft.currentStepId
        : plan.steps.first.id;
    final eligibleCompleted =
        draft.completedStepIds.where(plan.contains).toSet();
    final reconciledDraft = draft.copyWith(
      currentStepId: stepId,
      completedStepIds: eligibleCompleted,
    );

    return OnboardingState(
      draft: reconciledDraft,
      flowPlan: plan,
      stepId: stepId,
      completedStepIds: eligibleCompleted,
    );
  }

  void initialize(OnboardingDraft draft) {
    if (state.isBusy) return;
    _state = _buildInitialState(draft);
    notifyListeners();
  }

  void selectMode(AppMode mode) {
    if (state.isBusy) return;

    final nextPlan = _planner(entryPath: _entryPath, mode: mode);
    final nextStepId = _planner.reconcileCurrentStep(
      currentStepId: state.stepId,
      previousPlan: state.flowPlan,
      nextPlan: nextPlan,
    );
    final eligibleCompleted =
        state.completedStepIds.where(nextPlan.contains).toSet();
    final nextDraft = state.draft.copyWith(
      status: OnboardingStatus.inProgress,
      selectedMode: mode,
      currentStepId: nextStepId,
      completedStepIds: eligibleCompleted,
    );

    _state = state.copyWith(
      draft: nextDraft,
      flowPlan: nextPlan,
      stepId: nextStepId,
      completedStepIds: eligibleCompleted,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
  }

  void previous() {
    if (!state.canGoBack) return;

    final previousStepId = state.flowPlan.steps[state.currentIndex - 1].id;
    _moveTo(previousStepId);
  }

  Future<void> next({required Future<void> Function() onFinish}) async {
    if (!state.canContinue) return;

    if (state.stepId == OnboardingStepId.review) {
      await _finish(onFinish);
      return;
    }

    final nextStepId = state.flowPlan.steps[state.currentIndex + 1].id;
    final completed = {...state.completedStepIds, state.stepId};
    final nextDraft = state.draft.copyWith(
      currentStepId: nextStepId,
      completedStepIds: completed,
    );
    _state = state.copyWith(
      draft: nextDraft,
      stepId: nextStepId,
      completedStepIds: completed,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
  }

  void setValidationErrors(Map<String, String> errors) {
    if (state.isBusy) return;
    _state = state.copyWith(validationErrors: errors);
    notifyListeners();
  }

  void _moveTo(OnboardingStepId stepId) {
    final nextDraft = state.draft.copyWith(currentStepId: stepId);
    _state = state.copyWith(
      draft: nextDraft,
      stepId: stepId,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
  }

  Future<void> _finish(Future<void> Function() onFinish) async {
    _state = state.copyWith(
      isCompleting: true,
      clearRetryableError: true,
    );
    notifyListeners();

    try {
      await onFinish();
    } catch (error) {
      _state = state.copyWith(retryableError: error);
    } finally {
      _state = state.copyWith(isCompleting: false);
      notifyListeners();
    }
  }
}

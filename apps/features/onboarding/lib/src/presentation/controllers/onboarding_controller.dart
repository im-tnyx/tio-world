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
    ProfileStepValidator profileValidator = const ProfileStepValidator(),
  })  : _entryPath = entryPath,
        _planner = planner,
        _profileValidator = profileValidator {
    _state = _buildInitialState(initialDraft ?? OnboardingDraft());
  }

  final OnboardingEntryPath _entryPath;
  final BuildOnboardingFlowUseCase _planner;
  final ProfileStepValidator _profileValidator;
  static const _profileFlow = ProfileFlowPlan();

  late OnboardingState _state;

  OnboardingState get state => _state;

  OnboardingState _buildInitialState(OnboardingDraft draft) {
    final plan = _planner(
      entryPath: _entryPath,
      mode: draft.selectedMode,
      workoutIntroChoice: draft.workoutIntroChoice,
    );
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

    final nextWorkoutIntroChoice =
        state.draft.selectedMode == AppMode.hybrid && mode == AppMode.hybrid
            ? state.draft.workoutIntroChoice
            : null;
    final nextPlan = _planner(
      entryPath: _entryPath,
      mode: mode,
      workoutIntroChoice: nextWorkoutIntroChoice,
    );
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
      workoutIntroChoice: nextWorkoutIntroChoice,
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

  void selectWorkoutIntroChoice(WorkoutIntroChoice choice) {
    if (state.isBusy) return;

    final nextPlan = _planner(
      entryPath: _entryPath,
      mode: state.draft.selectedMode,
      workoutIntroChoice: choice,
    );
    final nextStepId = _planner.reconcileCurrentStep(
      currentStepId: state.stepId,
      previousPlan: state.flowPlan,
      nextPlan: nextPlan,
    );
    final eligibleCompleted =
        state.completedStepIds.where(nextPlan.contains).toSet();
    final nextDraft = state.draft.copyWith(
      status: OnboardingStatus.inProgress,
      workoutIntroChoice: choice,
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

  void updateProfileName(String value) {
    _updateProfile(state.draft.profile.copyWith(name: value));
  }

  void updateProfileGender(ProfileGender value) {
    _updateProfile(state.draft.profile.copyWith(gender: value));
  }

  void toggleProfileGoal(ProfileGoal goal) {
    final goals = {...state.draft.profile.goals};
    if (ProfileStepValidator.primaryGoals.contains(goal)) {
      final wasSelected = goals.contains(goal);
      goals.removeAll(ProfileStepValidator.primaryGoals);
      if (!wasSelected) goals.add(goal);
    } else if (!goals.remove(goal)) {
      goals.add(goal);
    }
    _updateProfile(state.draft.profile.copyWith(goals: goals));
  }

  void updateProfileDateOfBirth(DateTime value) {
    _updateProfile(
      state.draft.profile.copyWith(
        dateOfBirth: DateTime(value.year, value.month, value.day),
      ),
    );
  }

  void updateProfileHeight(double? value) {
    _updateProfile(
      state.draft.profile.copyWith(
        heightCm: value,
        clearHeightCm: value == null,
      ),
    );
  }

  void updateProfileCurrentWeight(double? value) {
    _updateProfile(
      state.draft.profile.copyWith(
        currentWeightKg: value,
        clearCurrentWeightKg: value == null,
      ),
    );
  }

  void updateProfileTargetWeight(double? value) {
    _updateProfile(
      state.draft.profile.copyWith(
        targetWeightKg: value,
        clearTargetWeightKg: value == null,
      ),
    );
  }

  void updateProfileActivity(ProfileActivityLevel value) {
    _updateProfile(state.draft.profile.copyWith(activityLevel: value));
  }

  void toggleProfileHealthCondition(ProfileHealthCondition condition) {
    final current = state.draft.profile;
    final conditions = {...current.healthConditions};
    var otherText = current.otherHealthCondition;

    if (condition == ProfileHealthCondition.none) {
      conditions
        ..clear()
        ..add(ProfileHealthCondition.none);
      otherText = '';
    } else {
      conditions.remove(ProfileHealthCondition.none);
      if (condition == ProfileHealthCondition.hypertension) {
        conditions.remove(ProfileHealthCondition.lowBloodPressure);
      } else if (condition == ProfileHealthCondition.lowBloodPressure) {
        conditions.remove(ProfileHealthCondition.hypertension);
      }

      if (!conditions.remove(condition)) conditions.add(condition);
      if (condition == ProfileHealthCondition.other &&
          !conditions.contains(ProfileHealthCondition.other)) {
        otherText = '';
      }
    }

    _updateProfile(
      current.copyWith(
        healthConditions: conditions,
        otherHealthCondition: otherText,
      ),
    );
  }

  void updateOtherHealthCondition(String value) {
    _updateProfile(
      state.draft.profile.copyWith(otherHealthCondition: value),
    );
  }

  void previous() {
    if (state.isBusy) return;

    if (state.stepId == OnboardingStepId.profileBasics) {
      final previousProfileStep =
          _profileFlow.previous(state.draft.profile.currentStepId);
      if (previousProfileStep != null) {
        _moveToProfileStep(previousProfileStep);
        return;
      }
    }

    if (!state.canGoBack) return;

    final previousStepId = state.flowPlan.steps[state.currentIndex - 1].id;
    _moveTo(previousStepId);
  }

  Future<void> next(
      {required Future<void> Function(OnboardingDraft draft) onFinish}) async {
    if (state.isBusy) return;

    if (state.stepId == OnboardingStepId.profileBasics) {
      final errors = _profileValidator.validate(state.draft.profile);
      if (errors.isNotEmpty) {
        _state = state.copyWith(
          validationErrors: {
            for (final entry in errors.entries) entry.key.name: entry.value,
          },
        );
        notifyListeners();
        return;
      }

      final nextProfileStep =
          _profileFlow.next(state.draft.profile.currentStepId);
      if (nextProfileStep != null) {
        _moveToProfileStep(nextProfileStep);
        return;
      }
    }

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

  void _updateProfile(ProfileOnboardingDraft profile) {
    if (state.isBusy) return;

    final completed = {...state.completedStepIds}
      ..remove(OnboardingStepId.profileBasics);
    final nextDraft = state.draft.copyWith(
      status: OnboardingStatus.inProgress,
      profile: profile,
      completedStepIds: completed,
    );
    _state = state.copyWith(
      draft: nextDraft,
      completedStepIds: completed,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
  }

  void _moveToProfileStep(ProfileStepId stepId) {
    final nextProfile = state.draft.profile.copyWith(currentStepId: stepId);
    final nextDraft = state.draft.copyWith(profile: nextProfile);
    _state = state.copyWith(
      draft: nextDraft,
      validationErrors: const {},
      clearRetryableError: true,
    );
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

  Future<void> _finish(
      Future<void> Function(OnboardingDraft draft) onFinish) async {
    _state = state.copyWith(
      isCompleting: true,
      clearRetryableError: true,
    );
    notifyListeners();

    try {
      await onFinish(state.draft);
    } catch (error) {
      _state = state.copyWith(retryableError: error);
    } finally {
      _state = state.copyWith(isCompleting: false);
      notifyListeners();
    }
  }
}

import 'dart:async';

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

final onboardingStatusRepositoryProvider =
    Provider<OnboardingStatusRepository>((ref) {
  return const NoOpOnboardingStatusRepository();
});

final onboardingDraftRepositoryProvider =
    Provider<OnboardingDraftRepository?>((ref) => null);

final onboardingCompletionValidatorProvider =
    Provider<OnboardingCompletionValidator>((ref) {
  return const OnboardingCompletionValidator();
});

final onboardingControllerProvider = ChangeNotifierProvider.autoDispose
    .family<OnboardingController, OnboardingControllerSeed>((ref, seed) {
  final controller = OnboardingController(
    entryPath: seed.entryPath,
    initialDraft: seed.draft,
    statusRepository: ref.watch(onboardingStatusRepositoryProvider),
    draftRepository: ref.watch(onboardingDraftRepositoryProvider),
    completionValidator: ref.watch(onboardingCompletionValidatorProvider),
  );
  unawaited(controller.hydrateDraft());
  return controller;
});

class OnboardingController extends ChangeNotifier {
  OnboardingController({
    required OnboardingEntryPath entryPath,
    OnboardingDraft? initialDraft,
    BuildOnboardingFlowUseCase planner = const BuildOnboardingFlowUseCase(),
    BuildWorkoutFlowPlanUseCase workoutPlanner =
        const BuildWorkoutFlowPlanUseCase(),
    ProfileStepValidator profileValidator = const ProfileStepValidator(),
    WorkoutStepValidator workoutValidator = const WorkoutStepValidator(),
    TargetStepValidator targetValidator = const TargetStepValidator(),
    OnboardingCompletionValidator completionValidator =
        const OnboardingCompletionValidator(),
    OnboardingStatusRepository statusRepository =
        const NoOpOnboardingStatusRepository(),
    OnboardingDraftRepository? draftRepository,
  })  : _entryPath = entryPath,
        _planner = planner,
        _workoutPlanner = workoutPlanner,
        _profileValidator = profileValidator,
        _workoutValidator = workoutValidator,
        _targetValidator = targetValidator,
        _completionValidator = completionValidator,
        _statusRepository = statusRepository,
        _draftRepository = draftRepository {
    _state = _buildInitialState(initialDraft ?? OnboardingDraft());
  }

  final OnboardingEntryPath _entryPath;
  final BuildOnboardingFlowUseCase _planner;
  final BuildWorkoutFlowPlanUseCase _workoutPlanner;
  final ProfileStepValidator _profileValidator;
  final WorkoutStepValidator _workoutValidator;
  final TargetStepValidator _targetValidator;
  final OnboardingCompletionValidator _completionValidator;
  final OnboardingStatusRepository _statusRepository;
  final OnboardingDraftRepository? _draftRepository;
  static const _profileFlow = ProfileFlowPlan();
  static const _targetsFlow = TargetsFlowPlan();

  bool _isHydrated = false;
  int _currentRevision = 0;
  int _lastSavedRevision = 0;
  Timer? _autosaveTimer;

  bool get isHydrated => _isHydrated;

  late OnboardingState _state;

  OnboardingState get state => _state;

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    super.dispose();
  }

  Future<void> hydrateDraft() async {
    if (_isHydrated) return;
    if (_draftRepository == null) {
      _isHydrated = true;
      return;
    }

    try {
      final snapshot = await _draftRepository.loadDraft();
      if (snapshot != null) {
        _state = _buildInitialState(snapshot.draft);
        notifyListeners();
      }
    } catch (_) {
      // Safe fallback: fresh state preserved if remote decode fails
    } finally {
      _isHydrated = true;
    }
  }

  void _scheduleDraftSave({bool immediate = false}) {
    if (!_isHydrated || _draftRepository == null) return;
    _currentRevision++;
    final revision = _currentRevision;

    _autosaveTimer?.cancel();
    if (immediate) {
      unawaited(_flushDraftSave(revision));
    } else {
      _autosaveTimer = Timer(const Duration(milliseconds: 300), () {
        unawaited(_flushDraftSave(revision));
      });
    }
  }

  Future<void> _flushDraftSave(int revision) async {
    if (revision <= _lastSavedRevision || _draftRepository == null) return;
    final draftToSave = state.draft;

    try {
      await _draftRepository.saveDraft(
        OnboardingDraftSnapshot(draft: draftToSave),
      );
      if (revision > _lastSavedRevision) {
        _lastSavedRevision = revision;
      }
    } catch (_) {
      // Retain in-memory draft; retryable on next change.
    }
  }

  OnboardingState _buildInitialState(OnboardingDraft draft) {
    final plan = _planner(
      entryPath: _entryPath,
      mode: draft.selectedMode,
      workoutIntroChoice: draft.workoutIntroChoice,
    );
    final workoutFlowPlan = _workoutPlanner(
      gymAccess: draft.workout.gymAccess,
    );
    final stepId = plan.contains(draft.currentStepId)
        ? draft.currentStepId
        : plan.steps.first.id;
    final eligibleCompleted =
        draft.completedStepIds.where(plan.contains).toSet();
    final workoutStepId = workoutFlowPlan.contains(draft.workout.currentStepId)
        ? draft.workout.currentStepId
        : workoutFlowPlan.steps.first;
    final reconciledDraft = draft.copyWith(
      currentStepId: stepId,
      workout: draft.workout.copyWith(currentStepId: workoutStepId),
      completedStepIds: eligibleCompleted,
    );

    return OnboardingState(
      draft: reconciledDraft,
      flowPlan: plan,
      workoutFlowPlan: workoutFlowPlan,
      stepId: stepId,
      completionEligibility: _completionValidator.evaluate(
        draft: reconciledDraft,
        flowPlan: plan,
      ),
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
    _markInProgress();

    final nextWorkoutIntroChoice =
        state.draft.selectedMode == AppMode.hybrid && mode == AppMode.hybrid
            ? state.draft.workoutIntroChoice
            : null;
    final nextPlan = _planner(
      entryPath: _entryPath,
      mode: mode,
      workoutIntroChoice: nextWorkoutIntroChoice,
    );
    final nextWorkoutFlowPlan = _workoutPlanner(
      gymAccess: state.draft.workout.gymAccess,
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

    _state = _copyState(
      draft: nextDraft,
      flowPlan: nextPlan,
      workoutFlowPlan: nextWorkoutFlowPlan,
      stepId: nextStepId,
      completedStepIds: eligibleCompleted,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave(immediate: true);
  }

  void selectWorkoutIntroChoice(WorkoutIntroChoice choice) {
    if (state.isBusy) return;
    _markInProgress();

    final nextPlan = _planner(
      entryPath: _entryPath,
      mode: state.draft.selectedMode,
      workoutIntroChoice: choice,
    );
    final nextWorkoutFlowPlan = _workoutPlanner(
      gymAccess: state.draft.workout.gymAccess,
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

    _state = _copyState(
      draft: nextDraft,
      flowPlan: nextPlan,
      workoutFlowPlan: nextWorkoutFlowPlan,
      stepId: nextStepId,
      completedStepIds: eligibleCompleted,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave(immediate: true);
  }

  void updateProfileName(String value) {
    _markInProgress();
    _updateProfile(state.draft.profile.copyWith(name: value));
  }

  void updateProfileGender(ProfileGender value) {
    _markInProgress();
    _updateProfile(state.draft.profile.copyWith(gender: value));
  }

  void toggleProfileGoal(ProfileGoal goal) {
    _markInProgress();
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
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(
        dateOfBirth: DateTime(value.year, value.month, value.day),
      ),
    );
  }

  void updateProfileHeight(double? value) {
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(
        heightCm: value,
        clearHeightCm: value == null,
      ),
    );
  }

  void updateProfileHeightUnit(String unit) {
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(heightUnit: unit),
    );
  }

  void updateProfileCurrentWeight(double? value) {
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(
        currentWeightKg: value,
        clearCurrentWeightKg: value == null,
      ),
    );
  }

  void updateProfileWeightUnit(String unit) {
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(weightUnit: unit),
    );
  }

  void updateProfileTargetWeight(double? value) {
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(
        targetWeightKg: value,
        clearTargetWeightKg: value == null,
      ),
    );
  }

  void updateProfileActivity(ProfileActivityLevel value) {
    _markInProgress();
    _updateProfile(state.draft.profile.copyWith(activityLevel: value));
  }

  void updateGymAccess(WorkoutGymAccess value) {
    if (state.isBusy) return;
    _markInProgress();

    final nextWorkoutFlowPlan = _workoutPlanner(gymAccess: value);
    final nextWorkoutStepId = _workoutPlanner.reconcileCurrentStep(
      currentStepId: state.draft.workout.currentStepId,
      previousPlan: state.workoutFlowPlan,
      nextPlan: nextWorkoutFlowPlan,
    );
    final nextWorkout = state.draft.workout.copyWith(
      gymAccess: value,
      currentStepId: nextWorkoutStepId,
    );

    _state = _copyState(
      draft: state.draft.copyWith(
        status: OnboardingStatus.inProgress,
        workout: nextWorkout,
      ),
      workoutFlowPlan: nextWorkoutFlowPlan,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
  }

  void toggleEquipment(WorkoutEquipment value) {
    _markInProgress();
    final nextEquipment = {...state.draft.workout.equipment};
    if (!nextEquipment.remove(value)) {
      nextEquipment.add(value);
    }
    _updateWorkout(
      state.draft.workout.copyWith(equipment: nextEquipment),
    );
  }

  void updateExperienceLevel(WorkoutExperienceLevel value) {
    _markInProgress();
    _updateWorkout(
      state.draft.workout.copyWith(experienceLevel: value),
    );
  }

  void toggleFocusArea(WorkoutFocusArea value) {
    _markInProgress();
    _updateWorkout(
      state.draft.workout.copyWith(
        focusAreas: WorkoutFocusAreaSelection.toggle(
          selectedAreas: state.draft.workout.focusAreas,
          area: value,
        ),
      ),
    );
  }

  void toggleTrainingDay(WorkoutTrainingDay value) {
    _markInProgress();
    final nextDays = {...state.draft.workout.trainingDays};
    if (!nextDays.remove(value)) {
      nextDays.add(value);
    }
    _updateWorkout(
      state.draft.workout.copyWith(trainingDays: nextDays),
    );
  }

  void updateWorkoutDuration(WorkoutDuration value) {
    _markInProgress();
    _updateWorkout(
      state.draft.workout.copyWith(workoutDuration: value),
    );
  }

  void updateWorkoutSplit(WorkoutSplit value) {
    _markInProgress();
    _updateWorkout(
      state.draft.workout.copyWith(workoutSplit: value),
    );
  }

  void updateWorkoutHealthConcerns(String value) {
    _markInProgress();
    _updateWorkout(
      state.draft.workout.copyWith(healthConcerns: value),
    );
  }

  void updateWorkoutSpecialEvent(String value) {
    _markInProgress();
    _updateWorkout(
      state.draft.workout.copyWith(specialEvent: value),
    );
  }

  void toggleProfileHealthCondition(ProfileHealthCondition condition) {
    _markInProgress();
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
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(otherHealthCondition: value),
    );
  }

  void updateProfileMobile(String value) {
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(mobile: value),
    );
  }

  void updateDailyStepTarget(int steps) {
    _markInProgress();
    _updateTargets(state.draft.targets.copyWith(dailySteps: steps));
  }

  void updateSleepTargetMinutes(int minutes) {
    _markInProgress();
    _updateTargets(state.draft.targets.copyWith(sleepTargetMinutes: minutes));
  }

  void updateSleepSchedule({
    int? sleepTimeMinutes,
    int? wakeTimeMinutes,
    int? durationMinutes,
  }) {
    _markInProgress();
    var current = state.draft.targets;
    if (sleepTimeMinutes != null) {
      final duration = durationMinutes ?? current.sleepTargetMinutes;
      final wake = SleepScheduleHelper.wakeTimeFromSleepAndDuration(
        sleepTimeMinutes,
        duration,
      );
      current = current.copyWith(
        sleepTimeMinutes: sleepTimeMinutes,
        wakeTimeMinutes: wake,
        sleepTargetMinutes: duration,
      );
    } else if (wakeTimeMinutes != null) {
      final duration = durationMinutes ??
          SleepScheduleHelper.adjustDurationOnWakeChange(
            current.sleepTimeMinutes,
            wakeTimeMinutes,
          );
      current = current.copyWith(
        wakeTimeMinutes: wakeTimeMinutes,
        sleepTargetMinutes: duration,
      );
    } else if (durationMinutes != null) {
      final wake = SleepScheduleHelper.wakeTimeFromSleepAndDuration(
        current.sleepTimeMinutes,
        durationMinutes,
      );
      current = current.copyWith(
        sleepTargetMinutes: durationMinutes,
        wakeTimeMinutes: wake,
      );
    }
    _updateTargets(current);
  }

  void updateWaterTargetMl(int millilitres) {
    _markInProgress();
    _updateTargets(state.draft.targets.copyWith(waterMl: millilitres));
  }

  void updateGoalPaceKgPerWeek(double value) {
    _markInProgress();
    _updateTargets(state.draft.targets.copyWith(goalPaceKgPerWeek: value));
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

    if (state.stepId == OnboardingStepId.workoutPreferences) {
      final currentWorkoutIndex =
          state.workoutFlowPlan.indexOf(state.draft.workout.currentStepId);
      if (currentWorkoutIndex > 0) {
        _moveToWorkoutStep(
            state.workoutFlowPlan.steps[currentWorkoutIndex - 1]);
        return;
      }
    }

    if (state.stepId == OnboardingStepId.targets) {
      final previousTargetStep =
          _targetsFlow.previous(state.draft.targets.currentStepId);
      if (previousTargetStep != null) {
        _moveToTargetStep(previousTargetStep);
        return;
      }
    }

    if (!state.canGoBack) return;

    final previousStepId = state.flowPlan.steps[state.currentIndex - 1].id;
    _moveTo(previousStepId);
  }

  Future<void> next({
    required Future<void> Function(OnboardingDraft draft) onFinish,
    Future<bool> Function()? onAuthRequired,
  }) async {
    if (state.isBusy) return;

    if (state.stepId == OnboardingStepId.profileBasics) {
      final errors = _profileValidator.validate(state.draft.profile);
      if (errors.isNotEmpty) {
        _state = _copyState(
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

      // Profile completed -> Trigger Sign Up authentication checkpoint
      if (onAuthRequired != null) {
        final authenticated = await onAuthRequired();
        if (!authenticated) return;
      }
    }

    if (state.stepId == OnboardingStepId.workoutPreferences) {
      final errors = _workoutValidator.validate(
        draft: state.draft.workout,
        flowPlan: state.workoutFlowPlan,
      );
      if (errors.isNotEmpty) {
        _state = _copyState(
          validationErrors: {
            for (final entry in errors.entries) entry.key.name: entry.value,
          },
        );
        notifyListeners();
        return;
      }

      final currentWorkoutIndex =
          state.workoutFlowPlan.indexOf(state.draft.workout.currentStepId);
      if (currentWorkoutIndex < state.workoutFlowPlan.stepCount - 1) {
        _moveToWorkoutStep(
            state.workoutFlowPlan.steps[currentWorkoutIndex + 1]);
        return;
      }
    }

    if (state.stepId == OnboardingStepId.targets) {
      final error = _targetValidator.validateCurrentStep(
        state.draft.targets,
        profile: state.draft.profile,
      );
      if (error != null) {
        _state = _copyState(
          validationErrors: {
            state.draft.targets.currentStepId.name: error,
          },
        );
        notifyListeners();
        return;
      }

      final nextTargetStep =
          _targetsFlow.next(state.draft.targets.currentStepId);
      if (nextTargetStep != null) {
        _moveToTargetStep(nextTargetStep);
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
    _state = _copyState(
      draft: nextDraft,
      stepId: nextStepId,
      completedStepIds: completed,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave(immediate: true);
  }

  void setValidationErrors(Map<String, String> errors) {
    if (state.isBusy) return;
    _state = _copyState(validationErrors: errors);
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
    _state = _copyState(
      draft: nextDraft,
      completedStepIds: completed,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave();
  }

  void _updateWorkout(WorkoutOnboardingDraft workout) {
    if (state.isBusy) return;

    final completed = {...state.completedStepIds}
      ..remove(OnboardingStepId.workoutPreferences);
    final nextDraft = state.draft.copyWith(
      status: OnboardingStatus.inProgress,
      workout: workout,
      completedStepIds: completed,
    );
    _state = _copyState(
      draft: nextDraft,
      completedStepIds: completed,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave();
  }

  void _updateTargets(TargetsOnboardingDraft targets) {
    if (state.isBusy) return;

    final completed = {...state.completedStepIds}
      ..remove(OnboardingStepId.targets);
    final nextDraft = state.draft.copyWith(
      status: OnboardingStatus.inProgress,
      targets: targets,
      completedStepIds: completed,
    );
    _state = _copyState(
      draft: nextDraft,
      completedStepIds: completed,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave();
  }

  void _moveToProfileStep(ProfileStepId stepId) {
    final nextProfile = state.draft.profile.copyWith(currentStepId: stepId);
    final nextDraft = state.draft.copyWith(profile: nextProfile);
    _state = _copyState(
      draft: nextDraft,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave(immediate: true);
  }

  void _moveTo(OnboardingStepId stepId) {
    final nextDraft = state.draft.copyWith(currentStepId: stepId);
    _state = _copyState(
      draft: nextDraft,
      stepId: stepId,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave(immediate: true);
  }

  void _moveToWorkoutStep(WorkoutStepId stepId) {
    final nextWorkout = state.draft.workout.copyWith(currentStepId: stepId);
    final nextDraft = state.draft.copyWith(workout: nextWorkout);
    _state = _copyState(
      draft: nextDraft,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave(immediate: true);
  }

  void _moveToTargetStep(TargetStepId stepId) {
    final nextTargets = state.draft.targets.copyWith(currentStepId: stepId);
    final nextDraft = state.draft.copyWith(targets: nextTargets);
    _state = _copyState(
      draft: nextDraft,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave(immediate: true);
  }

  Future<void> _finish(
    Future<void> Function(OnboardingDraft draft) onFinish,
  ) async {
    _state = _copyState(
      isCompleting: true,
      clearRetryableError: true,
    );
    notifyListeners();

    try {
      await onFinish(state.draft);
    } catch (error) {
      _state = _copyState(retryableError: error);
    } finally {
      _state = _copyState(isCompleting: false);
      notifyListeners();
    }
  }

  OnboardingState _copyState({
    OnboardingDraft? draft,
    OnboardingFlowPlan? flowPlan,
    WorkoutFlowPlan? workoutFlowPlan,
    OnboardingStepId? stepId,
    Set<OnboardingStepId>? completedStepIds,
    Map<String, String>? validationErrors,
    bool? isInitializing,
    bool? isSaving,
    bool? isCompleting,
    Object? retryableError,
    bool clearRetryableError = false,
  }) {
    var nextDraft = draft ?? state.draft;
    final nextFlowPlan = flowPlan ?? state.flowPlan;
    final nextWorkoutFlowPlan = workoutFlowPlan ??
        _workoutPlanner(gymAccess: nextDraft.workout.gymAccess);
    if (!nextWorkoutFlowPlan.contains(nextDraft.workout.currentStepId)) {
      nextDraft = nextDraft.copyWith(
        workout: nextDraft.workout.copyWith(
          currentStepId: nextWorkoutFlowPlan.steps.first,
        ),
      );
    }

    return state.copyWith(
      draft: nextDraft,
      flowPlan: nextFlowPlan,
      workoutFlowPlan: nextWorkoutFlowPlan,
      stepId: stepId,
      completionEligibility: _completionValidator.evaluate(
        draft: nextDraft,
        flowPlan: nextFlowPlan,
      ),
      completedStepIds: completedStepIds,
      validationErrors: validationErrors,
      isInitializing: isInitializing,
      isSaving: isSaving,
      isCompleting: isCompleting,
      retryableError: retryableError,
      clearRetryableError: clearRetryableError,
    );
  }

  void _markInProgress() {
    if (state.draft.status == OnboardingStatus.completed) return;

    if (state.draft.status != OnboardingStatus.inProgress) {
      final nextDraft = state.draft.copyWith(
        status: OnboardingStatus.inProgress,
      );
      _state = _copyState(
        draft: nextDraft,
        clearRetryableError: true,
      );
      notifyListeners();
    }

    unawaited(_persistInProgress());
  }

  Future<Future<void>?> _persistInProgress() async {
    try {
      await _statusRepository.write(OnboardingStatus.inProgress);
    } catch (_) {
      // Fail safe: onboarding remains incomplete and restart still returns to onboarding.
    }
    return null;
  }
}

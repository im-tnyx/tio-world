import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/domain.dart';
import '../state/state.dart';

class OnboardingControllerSeed {
  OnboardingControllerSeed({
    required this.entryPath,
    OnboardingDraft? draft,
    this.includeMobile = false,
  }) : draft = draft ?? OnboardingDraft();

  final OnboardingEntryPath entryPath;
  final OnboardingDraft draft;
  final bool includeMobile;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OnboardingControllerSeed &&
            entryPath == other.entryPath &&
            draft == other.draft &&
            includeMobile == other.includeMobile;
  }

  @override
  int get hashCode => Object.hash(entryPath, draft, includeMobile);
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
    includeMobile: seed.includeMobile,
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
    this.includeMobile = false,
    BuildOnboardingFlowUseCase planner = const BuildOnboardingFlowUseCase(),
    BuildProfileFlowPlanUseCase profilePlanner =
        const BuildProfileFlowPlanUseCase(),
    BuildWorkoutFlowPlanUseCase workoutPlanner =
        const BuildWorkoutFlowPlanUseCase(),
    BuildTargetsFlowPlanUseCase targetsPlanner =
        const BuildTargetsFlowPlanUseCase(),
    ProfileStepValidator profileValidator = const ProfileStepValidator(),
    WorkoutStepValidator workoutValidator = const WorkoutStepValidator(),
    TargetStepValidator targetValidator = const TargetStepValidator(),
    GoalIntentSelectionPolicy goalSelectionPolicy =
        const GoalIntentSelectionPolicy(),
    WeightGoalFlowPolicy weightGoalPolicy = const WeightGoalFlowPolicy(),
    TargetWeightRecommendationResolver targetWeightRecommendationResolver =
        const TargetWeightRecommendationResolver(),
    LegacyProfileGoalIntentMigration legacyGoalMigration =
        const LegacyProfileGoalIntentMigration(),
    OnboardingCompletionValidator completionValidator =
        const OnboardingCompletionValidator(),
    OnboardingStatusRepository statusRepository =
        const NoOpOnboardingStatusRepository(),
    OnboardingDraftRepository? draftRepository,
  })  : _entryPath = entryPath,
        _planner = planner,
        _profilePlanner = profilePlanner,
        _workoutPlanner = workoutPlanner,
        _targetsPlanner = targetsPlanner,
        _profileValidator = profileValidator,
        _workoutValidator = workoutValidator,
        _targetValidator = targetValidator,
        _goalSelectionPolicy = goalSelectionPolicy,
        _weightGoalPolicy = weightGoalPolicy,
        _targetWeightRecommendationResolver = targetWeightRecommendationResolver,
        _legacyGoalMigration = legacyGoalMigration,
        _completionValidator = completionValidator,
        _statusRepository = statusRepository,
        _draftRepository = draftRepository {
    _state = _buildInitialState(initialDraft ?? OnboardingDraft());
  }

  final OnboardingEntryPath _entryPath;
  final bool includeMobile;
  final BuildOnboardingFlowUseCase _planner;
  final BuildProfileFlowPlanUseCase _profilePlanner;
  final BuildWorkoutFlowPlanUseCase _workoutPlanner;
  final BuildTargetsFlowPlanUseCase _targetsPlanner;
  final ProfileStepValidator _profileValidator;
  final WorkoutStepValidator _workoutValidator;
  final TargetStepValidator _targetValidator;
  final GoalIntentSelectionPolicy _goalSelectionPolicy;
  final WeightGoalFlowPolicy _weightGoalPolicy;
  final TargetWeightRecommendationResolver _targetWeightRecommendationResolver;
  final LegacyProfileGoalIntentMigration _legacyGoalMigration;
  final OnboardingCompletionValidator _completionValidator;
  final OnboardingStatusRepository _statusRepository;
  final OnboardingDraftRepository? _draftRepository;

  static const double _defaultHeightCm = 170.0;
  static const double _defaultCurrentWeightKg = 75.0;

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
      includeMobile: includeMobile,
    );
    final workoutFlowPlan = _workoutPlanner(
      gymAccess: draft.workout.gymAccess,
    );
    var stepId = plan.contains(draft.currentStepId)
        ? draft.currentStepId
        : plan.steps.first.id;
    final eligibleCompleted =
        draft.completedStepIds.where(plan.contains).toSet();
    final workoutStepId = workoutFlowPlan.contains(draft.workout.currentStepId)
        ? draft.workout.currentStepId
        : workoutFlowPlan.steps.first;

    var profile = draft.profile;
    var targets = draft.targets;
    final goalSelection = _resolvedGoalSelection(draft);
    final mode = draft.selectedMode;
    final resolvedDirection = _weightGoalPolicy.directionFor(
      mode: mode,
      selection: goalSelection,
    );
    if (profile.targetWeightKg != null &&
        profile.targetWeightDirection == null &&
        resolvedDirection != null) {
      profile = profile.copyWith(targetWeightDirection: resolvedDirection);
    }
    profile = _reconcileTargetWeightForDirection(
      profile: profile,
      nextDirection: resolvedDirection,
    );

    var profileFlowPlan = _profilePlanner(
      mode: mode,
      goalSelection: goalSelection,
    );
    var targetsFlowPlan = _targetsPlanner(
      mode: mode,
      goalSelection: goalSelection,
    );

    if (!profileFlowPlan.contains(profile.currentStepId)) {
      profile = profile.copyWith(
        currentStepId: _profilePlanner.reconcileCurrentStep(
          currentStepId: profile.currentStepId,
          previousPlan: const ProfileFlowPlan(),
          nextPlan: profileFlowPlan,
        ),
      );
    }
    if (!targetsFlowPlan.contains(targets.currentStepId)) {
      targets = targets.copyWith(
        currentStepId: _targetsPlanner.reconcileCurrentStep(
          currentStepId: targets.currentStepId,
          previousPlan: const TargetsFlowPlan(),
          nextPlan: targetsFlowPlan,
        ),
      );
    }

    if (mode != null &&
        _goalSelectionPolicy.validate(
              mode: mode,
              selection: goalSelection,
            ) !=
            null &&
        _isPastGoalCheckpoint(
          stepId: stepId,
          profileStepId: profile.currentStepId,
          flowPlan: plan,
          completedStepIds: eligibleCompleted,
          profileFlowPlan: profileFlowPlan,
        )) {
      stepId = OnboardingStepId.profileBasics;
      profile = profile.copyWith(currentStepId: ProfileStepId.goal);
      eligibleCompleted.remove(OnboardingStepId.profileBasics);
      profileFlowPlan = _profilePlanner(
        mode: mode,
        goalSelection: goalSelection,
      );
      targetsFlowPlan = _targetsPlanner(
        mode: mode,
        goalSelection: goalSelection,
      );
    }

    profile = _prepareProfileForStep(
      profile: profile,
      stepId: profile.currentStepId,
      mode: mode,
      goalSelection: goalSelection,
    );

    final reconciledDraft = draft.copyWith(
      goalSelection: goalSelection,
      currentStepId: stepId,
      profile: profile,
      workout: draft.workout.copyWith(currentStepId: workoutStepId),
      targets: targets,
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

  GoalIntentSelection _resolvedGoalSelection(OnboardingDraft draft) {
    final mode = draft.selectedMode;
    if (mode == null) return draft.goalSelection;

    var selection = draft.goalSelection;
    if (selection.primaryGoal == null && draft.profile.goals.isNotEmpty) {
      selection = _legacyGoalMigration(
        mode: mode,
        legacyGoals: draft.profile.goals,
      );
    }
    return _goalSelectionPolicy.reconcileForMode(
      mode: mode,
      selection: selection,
    );
  }

  bool _isPastGoalCheckpoint({
    required OnboardingStepId stepId,
    required ProfileStepId profileStepId,
    required OnboardingFlowPlan flowPlan,
    required Set<OnboardingStepId> completedStepIds,
    required ProfileFlowPlan profileFlowPlan,
  }) {
    if (completedStepIds.contains(OnboardingStepId.profileBasics)) return true;

    if (stepId == OnboardingStepId.profileBasics) {
      return profileFlowPlan.indexOf(profileStepId) >
          profileFlowPlan.indexOf(ProfileStepId.goal);
    }

    final profileIndex =
        flowPlan.stepIds.indexOf(OnboardingStepId.profileBasics);
    final currentIndex = flowPlan.stepIds.indexOf(stepId);
    return profileIndex >= 0 && currentIndex > profileIndex;
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
      includeMobile: includeMobile,
    );
    final nextWorkoutFlowPlan = _workoutPlanner(
      gymAccess: state.draft.workout.gymAccess,
    );
    var nextStepId = _planner.reconcileCurrentStep(
      currentStepId: state.stepId,
      previousPlan: state.flowPlan,
      nextPlan: nextPlan,
    );
    final nextGoalSelection = _goalSelectionPolicy.reconcileForMode(
      mode: mode,
      selection: state.draft.goalSelection,
    );
    final nextDirection = _weightGoalPolicy.directionFor(
      mode: mode,
      selection: nextGoalSelection,
    );
    final goalChanged = nextGoalSelection != state.draft.goalSelection;
    final eligibleCompleted =
        state.completedStepIds.where(nextPlan.contains).toSet();
    var nextProfile = _reconcileTargetWeightForDirection(
      profile: state.draft.profile,
      nextDirection: nextDirection,
    );

    if (goalChanged &&
        _isPastGoalCheckpoint(
          stepId: nextStepId,
          profileStepId: nextProfile.currentStepId,
          flowPlan: nextPlan,
          completedStepIds: eligibleCompleted,
          profileFlowPlan: _profilePlanner(
            mode: mode,
            goalSelection: nextGoalSelection,
          ),
        )) {
      nextStepId = OnboardingStepId.profileBasics;
      nextProfile = nextProfile.copyWith(currentStepId: ProfileStepId.goal);
      eligibleCompleted.remove(OnboardingStepId.profileBasics);
    }

    final nextDraft = state.draft.copyWith(
      status: OnboardingStatus.inProgress,
      selectedMode: mode,
      workoutIntroChoice: nextWorkoutIntroChoice,
      goalSelection: nextGoalSelection,
      currentStepId: nextStepId,
      profile: nextProfile,
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
      includeMobile: includeMobile,
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

  void tapGoalIntent(GoalIntent goal) {
    if (state.isBusy) return;
    final mode = state.draft.selectedMode;
    if (mode == null) return;

    _markInProgress();
    final nextSelection = _goalSelectionPolicy.applyTap(
      mode: mode,
      current: state.draft.goalSelection,
      tappedGoal: goal,
    );
    _updateGoalSelection(nextSelection);
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

  void updateMeasurementUnitPreferences(
    MeasurementUnitPreferences preferences,
  ) {
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(unitPreferences: preferences),
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
    final direction = state.weightGoalDirection;
    if (value != null && direction == null) return;
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(
        targetWeightKg: value,
        targetWeightDirection: direction,
        clearTargetWeightKg: value == null,
        clearTargetWeightDirection: value == null,
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

  void updateProfileMobileVerified(bool isVerified) {
    _markInProgress();
    _updateProfile(
      state.draft.profile.copyWith(isMobileVerified: isVerified),
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
          state.profileFlowPlan.previous(state.draft.profile.currentStepId);
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
          state.targetsFlowPlan.previous(state.draft.targets.currentStepId);
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
      final currentProfileStep = state.draft.profile.currentStepId;
      if (currentProfileStep == ProfileStepId.goal) {
        final mode = state.draft.selectedMode;
        final error = mode == null
            ? 'Choose an App Mode before selecting goals.'
            : _goalSelectionPolicy.validate(
                mode: mode,
                selection: state.draft.goalSelection,
              );
        if (error != null) {
          _state = _copyState(
            validationErrors: {ProfileStepId.goal.name: error},
          );
          notifyListeners();
          return;
        }
      } else {
        final errors = _profileValidator.validate(
          state.draft.profile,
          weightGoalDirection: state.weightGoalDirection,
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
      }

      final nextProfileStep =
          state.profileFlowPlan.next(currentProfileStep);
      if (nextProfileStep != null) {
        _moveToProfileStep(nextProfileStep);
        return;
      }

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
        weightGoalDirection: state.weightGoalDirection,
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
          state.targetsFlowPlan.next(state.draft.targets.currentStepId);
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

  void _updateGoalSelection(GoalIntentSelection selection) {
    if (state.isBusy) return;

    final nextDirection = _weightGoalPolicy.directionFor(
      mode: state.draft.selectedMode,
      selection: selection,
    );
    final completed = {...state.completedStepIds}
      ..remove(OnboardingStepId.profileBasics);
    final profile = _reconcileTargetWeightForDirection(
      profile: state.draft.profile,
      nextDirection: nextDirection,
    );
    final nextDraft = state.draft.copyWith(
      status: OnboardingStatus.inProgress,
      goalSelection: selection,
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

  ProfileOnboardingDraft _reconcileTargetWeightForDirection({
    required ProfileOnboardingDraft profile,
    required GoalWeightDirection? nextDirection,
  }) {
    if (nextDirection == null || profile.targetWeightKg == null) {
      return profile;
    }
    if (profile.targetWeightDirection == nextDirection) {
      return profile;
    }
    return profile.copyWith(clearTargetWeightKg: true);
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
    final nextProfile = _prepareProfileForStep(
      profile: state.draft.profile.copyWith(currentStepId: stepId),
      stepId: stepId,
      mode: state.draft.selectedMode,
      goalSelection: state.draft.goalSelection,
    );
    final nextDraft = state.draft.copyWith(profile: nextProfile);
    _state = _copyState(
      draft: nextDraft,
      validationErrors: const {},
      clearRetryableError: true,
    );
    notifyListeners();
    _scheduleDraftSave(immediate: true);
  }

  ProfileOnboardingDraft _prepareProfileForStep({
    required ProfileOnboardingDraft profile,
    required ProfileStepId stepId,
    required AppMode? mode,
    required GoalIntentSelection goalSelection,
  }) {
    if (stepId == ProfileStepId.height && profile.heightCm == null) {
      return profile.copyWith(heightCm: _defaultHeightCm);
    }
    if (stepId == ProfileStepId.currentWeight &&
        profile.currentWeightKg == null) {
      return profile.copyWith(currentWeightKg: _defaultCurrentWeightKg);
    }
    if (stepId == ProfileStepId.targetWeight) {
      final direction = _weightGoalPolicy.directionFor(
        mode: mode,
        selection: goalSelection,
      );
      var reconciled = _reconcileTargetWeightForDirection(
        profile: profile,
        nextDirection: direction,
      );
      if (direction == null || reconciled.targetWeightKg != null) {
        return reconciled;
      }
      final recommendation = _targetWeightRecommendationResolver.resolve(
        direction: direction,
        currentWeightKg: reconciled.currentWeightKg,
        heightCm: reconciled.heightCm,
      );
      if (recommendation != null) {
        reconciled = reconciled.copyWith(
          targetWeightKg: recommendation,
          targetWeightDirection: direction,
        );
      }
      return reconciled;
    }
    return profile;
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
    } catch (error, stackTrace) {
      debugPrint('[OnboardingController] _finish error: $error');
      debugPrint('[OnboardingController] stackTrace: $stackTrace');
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

    final nextProfileFlowPlan = _profilePlanner(
      mode: nextDraft.selectedMode,
      goalSelection: nextDraft.goalSelection,
    );
    if (!nextProfileFlowPlan.contains(nextDraft.profile.currentStepId)) {
      nextDraft = nextDraft.copyWith(
        profile: nextDraft.profile.copyWith(
          currentStepId: _profilePlanner.reconcileCurrentStep(
            currentStepId: nextDraft.profile.currentStepId,
            previousPlan: state.profileFlowPlan,
            nextPlan: nextProfileFlowPlan,
          ),
        ),
      );
    }

    final nextTargetsFlowPlan = _targetsPlanner(
      mode: nextDraft.selectedMode,
      goalSelection: nextDraft.goalSelection,
    );
    if (!nextTargetsFlowPlan.contains(nextDraft.targets.currentStepId)) {
      nextDraft = nextDraft.copyWith(
        targets: nextDraft.targets.copyWith(
          currentStepId: _targetsPlanner.reconcileCurrentStep(
            currentStepId: nextDraft.targets.currentStepId,
            previousPlan: state.targetsFlowPlan,
            nextPlan: nextTargetsFlowPlan,
          ),
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

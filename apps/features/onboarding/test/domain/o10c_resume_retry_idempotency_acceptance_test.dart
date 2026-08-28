import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  test(
      'O10C persisted Review survives remote completion failure, retry converges, completed replay is idempotent',
      () async {
    final draft = OnboardingDraft(
      status: OnboardingStatus.inProgress,
      selectedMode: AppMode.workout,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.stayFit,
        supportingGoal: GoalIntent.improveEndurance,
      ),
      currentStepId: OnboardingStepId.review,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.workout,
    );
    final draftRepository = _RecordingDraftRepository(
      snapshot: OnboardingDraftSnapshot(draft: draft),
    );

    final resumeController = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      draftRepository: draftRepository,
      completionValidator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );
    await resumeController.hydrateDraft();

    expect(resumeController.state.stepId, OnboardingStepId.review);
    expect(resumeController.state.draft.selectedMode, AppMode.workout);
    expect(draftRepository.loadCalls, 1);

    final profileRepo = _CountingUserProfileRepository();
    final bodyRepo = body_owner.InMemoryBodySetupRepository();
    final wellnessRepo = body_owner.InMemoryWellnessTargetsRepository();
    final nutritionProfileRepo =
        nutrition_owner.InMemoryNutritionProfileRepository();
    final nutritionTargetsRepo =
        nutrition_owner.InMemoryNutritionTargetsRepository();
    final workoutProfileRepo = workout_owner.InMemoryWorkoutProfileRepository();
    final workoutTargetsRepo = workout_owner.InMemoryWorkoutTargetsRepository();

    final statusRepository = _CountingOnboardingStatusRepository();
    final modePreference = _CountingAppModePreference();
    final remoteState = _FailOnceCompletionAndPreferencesRepository();

    final complete = CompleteOnboardingUseCase(
      confirmedModePreference: modePreference,
      appPreferencesRepository: remoteState,
      statusRepository: statusRepository,
      completionRepository: remoteState,
      draftRepository: draftRepository,
      persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        nutritionTargetsRepository: nutritionTargetsRepo,
        workoutProfileRepository: workoutProfileRepo,
        workoutTargetsRepository: workoutTargetsRepo,
      ),
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    await expectLater(
      () => complete(draft: draft, flowPlan: flowPlan),
      throwsStateError,
    );

    // Owner and preference publication before the remote completion boundary is
    // durable/retry-safe, but local completion and draft cleanup must not occur.
    expect(profileRepo.upsertCalls, 1);
    expect(remoteState.preferenceUpsertCalls, 1);
    expect(modePreference.writeCalls, 1);
    expect(remoteState.markCalls, 1);
    expect(statusRepository.completedWriteCalls, 0);
    expect(draftRepository.clearCalls, 0);
    expect(draftRepository.snapshot, isNotNull);
    expect(remoteState.completionState,
        RemoteOnboardingCompletionState.incomplete);

    await complete(draft: draft, flowPlan: flowPlan);

    // Retry replays idempotent writes until the remote completion boundary
    // succeeds, then publishes local completion and clears the draft.
    expect(profileRepo.upsertCalls, 2);
    expect(remoteState.preferenceUpsertCalls, 2);
    expect(modePreference.writeCalls, 2);
    expect(remoteState.markCalls, 2);
    expect(remoteState.completionState,
        RemoteOnboardingCompletionState.completed);
    expect(statusRepository.status, OnboardingStatus.completed);
    expect(statusRepository.completedWriteCalls, 1);
    expect(draftRepository.clearCalls, 1);
    expect(draftRepository.snapshot, isNull);

    final writesAfterSuccess = (
      profile: profileRepo.upsertCalls,
      preferences: remoteState.preferenceUpsertCalls,
      mode: modePreference.writeCalls,
      remoteCompletion: remoteState.markCalls,
      localCompletion: statusRepository.completedWriteCalls,
      draftClear: draftRepository.clearCalls,
    );

    // An accidental repeated Finish after fully completed canonical state must
    // return idempotently without another semantic publication/write cycle.
    await complete(draft: draft, flowPlan: flowPlan);

    expect(profileRepo.upsertCalls, writesAfterSuccess.profile);
    expect(remoteState.preferenceUpsertCalls, writesAfterSuccess.preferences);
    expect(modePreference.writeCalls, writesAfterSuccess.mode);
    expect(remoteState.markCalls, writesAfterSuccess.remoteCompletion);
    expect(
      statusRepository.completedWriteCalls,
      writesAfterSuccess.localCompletion,
    );
    expect(draftRepository.clearCalls, writesAfterSuccess.draftClear);

    resumeController.dispose();
  });
}

class _CountingUserProfileRepository
    implements profile_owner.UserProfileRepository {
  profile_owner.UserProfileData? data;
  int upsertCalls = 0;

  @override
  Future<profile_owner.UserProfileData?> read() async => data;

  @override
  Future<void> upsert(profile_owner.UserProfileData profile) async {
    upsertCalls++;
    data = profile;
  }
}

class _FailOnceCompletionAndPreferencesRepository
    implements OnboardingCompletionRepository, AppPreferencesRepository {
  RemoteOnboardingCompletionState completionState =
      RemoteOnboardingCompletionState.incomplete;
  AppPreferencesState preferencesState = const AppPreferencesState.missing();
  int preferenceUpsertCalls = 0;
  int markCalls = 0;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async => completionState;

  @override
  Future<void> markCurrentCompleted() async {
    markCalls++;
    if (markCalls == 1) {
      throw StateError('remote completion failed once');
    }
    completionState = RemoteOnboardingCompletionState.completed;
  }

  @override
  Future<AppPreferencesState> read() async => preferencesState;

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    preferenceUpsertCalls++;
    preferencesState = AppPreferencesState.present(
      appMode: preferences.appMode,
      activeTabs: preferences.activeTabs,
    );
  }
}

class _CountingAppModePreference implements AppModePreference {
  AppMode? storedMode;
  int writeCalls = 0;

  @override
  Future<void> clear() async {
    storedMode = null;
  }

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
    writeCalls++;
    storedMode = mode;
  }
}

class _CountingOnboardingStatusRepository
    implements OnboardingStatusRepository {
  OnboardingStatus? status;
  bool hasStoredContractVersion = false;
  int completedWriteCalls = 0;

  @override
  Future<void> clear() async {
    status = null;
    hasStoredContractVersion = false;
  }

  @override
  Future<void> ensureInitialized() async {
    hasStoredContractVersion = true;
  }

  @override
  Future<OnboardingStatusSnapshot> read() async => OnboardingStatusSnapshot(
        status: status,
        hasStoredContractVersion: hasStoredContractVersion,
      );

  @override
  Future<void> write(OnboardingStatus next) async {
    if (next == OnboardingStatus.completed) {
      completedWriteCalls++;
    }
    status = next;
    hasStoredContractVersion = true;
  }
}

class _RecordingDraftRepository implements OnboardingDraftRepository {
  _RecordingDraftRepository({this.snapshot});

  OnboardingDraftSnapshot? snapshot;
  int loadCalls = 0;
  int clearCalls = 0;

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    loadCalls++;
    return snapshot;
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot next) async {
    snapshot = next;
  }

  @override
  Future<void> clearDraft() async {
    clearCalls++;
    snapshot = null;
  }
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    name: 'Tio User',
    gender: ProfileGender.female,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(1996, 6, 15),
    heightCm: 165,
    currentWeightKg: 60,
    targetWeightKg: 58,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _validWorkout() {
  return const WorkoutOnboardingDraft(
    gymAccess: WorkoutGymAccess.gym,
    equipment: {},
    experienceLevel: WorkoutExperienceLevel.intermediate,
    focusAreas: {WorkoutFocusArea.fullBody},
    trainingDays: {WorkoutTrainingDay.monday, WorkoutTrainingDay.thursday},
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.upperLower,
    specialEvent: '10K race',
  );
}

TargetsOnboardingDraft _validTargets() {
  return const TargetsOnboardingDraft(
    dailySteps: 10000,
    sleepTargetMinutes: 480,
    sleepTimeMinutes: 1320,
    wakeTimeMinutes: 360,
    waterMl: 2500,
    goalPaceKgPerWeek: 0.5,
  );
}

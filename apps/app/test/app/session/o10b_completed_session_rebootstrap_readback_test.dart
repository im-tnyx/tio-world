import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  test(
      'O10B completed Hybrid later rebootstrap restores canonical truth over stale local state',
      () async {
    final profileRepo = _FakeUserProfileRepository();
    final bodyRepo = body_owner.InMemoryBodySetupRepository();
    final wellnessRepo = body_owner.InMemoryWellnessTargetsRepository();
    final nutritionProfileRepo =
        nutrition_owner.InMemoryNutritionProfileRepository();
    final nutritionTargetsRepo =
        nutrition_owner.InMemoryNutritionTargetsRepository();
    final workoutProfileRepo = workout_owner.InMemoryWorkoutProfileRepository();
    final workoutTargetsRepo = workout_owner.InMemoryWorkoutTargetsRepository();

    final draft = OnboardingDraft(
      status: OnboardingStatus.inProgress,
      selectedMode: AppMode.hybrid,
      workoutIntroChoice: WorkoutIntroChoice.later,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.stayFit,
        supportingGoal: GoalIntent.improveEndurance,
      ),
      currentStepId: OnboardingStepId.review,
      profile: _validProfile(),
      nutrition: const NutritionOnboardingDraft(
        dietType: NutritionDietType.vegetarian,
        allergyRestrictions: {NutritionAllergyRestriction.none},
      ),
      // Deliberately retain complete dormant Workout answers. Hybrid later must
      // not publish them as active Workout canonical owners.
      workout: _validWorkout(),
      targets: _validTargets(),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.hybrid,
      workoutIntroChoice: WorkoutIntroChoice.later,
    );

    final draftRepository = _RecordingDraftRepository(
      snapshot: OnboardingDraftSnapshot(draft: draft),
    );
    final finalizationStatusRepository = _FakeOnboardingStatusRepository();
    final finalizationModePreference = _FakeAppModePreference();
    final remoteState = _CompletionAndPreferencesRepository();

    final complete = CompleteOnboardingUseCase(
      confirmedModePreference: finalizationModePreference,
      appPreferencesRepository: remoteState,
      statusRepository: finalizationStatusRepository,
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

    await complete(draft: draft, flowPlan: flowPlan);

    expect(remoteState.completionState,
        RemoteOnboardingCompletionState.completed);
    expect(remoteState.preferencesState.appMode, AppMode.hybrid);
    expect(
      remoteState.preferencesState.activeTabs,
      AppMode.hybrid.guidedDestinations,
    );
    expect(finalizationStatusRepository.status, OnboardingStatus.completed);
    expect(draftRepository.snapshot, isNull);

    expect(profileRepo.data?.name, 'Tio User');
    expect(bodyRepo.data?.currentWeightKg, 60);
    expect(wellnessRepo.data?.dailySteps, 10000);
    expect(await nutritionProfileRepo.read(), isNotNull);
    expect(await nutritionTargetsRepo.read(), isNotNull);
    expect(await workoutProfileRepo.read(), isNull);
    expect(await workoutTargetsRepo.read(), isNull);

    // Simulate residue after completion: a stale draft exists again and the
    // device-local cache points at Workout. Neither is account authority.
    await draftRepository.saveDraft(
      OnboardingDraftSnapshot(
        draft: OnboardingDraft(
          status: OnboardingStatus.inProgress,
          selectedMode: AppMode.workout,
          currentStepId: OnboardingStepId.profileBasics,
        ),
      ),
    );
    expect(draftRepository.snapshot, isNotNull);
    final clearCallsBeforeBootstrap = draftRepository.clearCalls;
    expect(draftRepository.loadCalls, 0);

    final staleLocalMode = _FakeAppModePreference(initialMode: AppMode.workout);
    final freshModeController = AppModeController(staleLocalMode);
    await freshModeController.load();
    expect(freshModeController.selectedMode, AppMode.workout);

    final freshStatusRepository = _FakeOnboardingStatusRepository(
      initialStatus: OnboardingStatus.notStarted,
      hasStoredContractVersion: true,
    );
    final freshStatusController = OnboardingStatusController(
      repository: freshStatusRepository,
      appModeController: freshModeController,
    );
    final bootstrap = AppSessionBootstrapController(
      authSessionRepository: const _AuthenticatedSessionRepository(),
      onboardingCompletionRepository: remoteState,
      onboardingStatusController: freshStatusController,
      onboardingDraftRepository: draftRepository,
      appPreferencesRepository: remoteState,
      appModeController: freshModeController,
    );

    await bootstrap.refresh();
    await _flushAsyncCleanup();

    expect(
      bootstrap.state,
      const AppSessionBootstrapReady(userId: 'user-a'),
    );
    expect(freshStatusController.status, OnboardingStatus.completed);
    expect(freshStatusRepository.status, OnboardingStatus.completed);

    // Canonical account preferences override stale device-local semantic mode.
    expect(freshModeController.selectedMode, AppMode.hybrid);
    expect(
      freshModeController.activeDestinations,
      AppMode.hybrid.guidedDestinations,
    );
    expect(staleLocalMode.storedMode, AppMode.hybrid);

    // Completed bootstrap never loads a stale onboarding draft as authority; it
    // only removes obsolete residue best-effort after reaching Ready.
    expect(draftRepository.loadCalls, 0);
    expect(draftRepository.clearCalls, clearCallsBeforeBootstrap + 1);
    expect(draftRepository.snapshot, isNull);

    // Canonical owner state remains readable across the new controller/session
    // boundary without any dependency on onboarding_drafts.
    expect(profileRepo.data?.name, 'Tio User');
    expect(bodyRepo.data?.currentWeightKg, 60);
    expect(wellnessRepo.data?.waterMl, 2500);
    expect(await nutritionProfileRepo.read(), isNotNull);
    final nutritionTargets = await nutritionTargetsRepo.read();
    expect(
      nutritionTargets?.customizationState,
      nutrition_owner.NutritionTargetCustomizationState.recommended,
    );
    expect(nutritionTargets?.recommendationMetadata['source'], 'onboarding');
    expect(await workoutProfileRepo.read(), isNull);
    expect(await workoutTargetsRepo.read(), isNull);

    expect(
      appModeRedirect(
        path: FeatureRoutes.home.path,
        selectedMode: freshModeController.selectedMode,
        activeDestinations: freshModeController.activeDestinations,
        onboardingStatus: freshStatusController.status,
      ),
      isNull,
    );
    expect(
      appModeRedirect(
        path: AppRoutes.onboarding.path,
        selectedMode: freshModeController.selectedMode,
        activeDestinations: freshModeController.activeDestinations,
        onboardingStatus: freshStatusController.status,
      ),
      FeatureRoutes.home.path,
    );

    bootstrap.dispose();
  });
}

Future<void> _flushAsyncCleanup() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _AuthenticatedSessionRepository implements AuthSessionRepository {
  const _AuthenticatedSessionRepository();

  static const state = AuthSessionAuthenticated(AuthSession(userId: 'user-a'));

  @override
  Stream<AuthSessionState> get sessionState => const Stream.empty();

  @override
  Future<AuthSessionState> get currentSessionState async => state;

  @override
  Future<void> signOut() async {}
}

class _FakeUserProfileRepository implements profile_owner.UserProfileRepository {
  profile_owner.UserProfileData? data;

  @override
  Future<profile_owner.UserProfileData?> read() async => data;

  @override
  Future<void> upsert(profile_owner.UserProfileData profile) async {
    data = profile;
  }
}

class _CompletionAndPreferencesRepository
    implements OnboardingCompletionRepository, AppPreferencesRepository {
  RemoteOnboardingCompletionState completionState =
      RemoteOnboardingCompletionState.incomplete;
  AppPreferencesState preferencesState = const AppPreferencesState.missing();

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async => completionState;

  @override
  Future<void> markCurrentCompleted() async {
    completionState = RemoteOnboardingCompletionState.completed;
  }

  @override
  Future<AppPreferencesState> read() async => preferencesState;

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    preferencesState = AppPreferencesState.present(
      appMode: preferences.appMode,
      activeTabs: preferences.activeTabs,
    );
  }
}

class _RecordingDraftRepository implements OnboardingDraftRepository {
  _RecordingDraftRepository({this.snapshot});

  OnboardingDraftSnapshot? snapshot;
  int loadCalls = 0;
  int saveCalls = 0;
  int clearCalls = 0;

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    loadCalls++;
    return snapshot;
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot next) async {
    saveCalls++;
    snapshot = next;
  }

  @override
  Future<void> clearDraft() async {
    clearCalls++;
    snapshot = null;
  }
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference({AppMode? initialMode}) : storedMode = initialMode;

  AppMode? storedMode;

  @override
  Future<void> clear() async {
    storedMode = null;
  }

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
    storedMode = mode;
  }
}

class _FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  _FakeOnboardingStatusRepository({
    this.initialStatus,
    this.hasStoredContractVersion = false,
  });

  final OnboardingStatus? initialStatus;
  OnboardingStatus? status;
  bool hasStoredContractVersion;

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
  Future<OnboardingStatusSnapshot> read() async {
    return OnboardingStatusSnapshot(
      status: status ?? initialStatus,
      hasStoredContractVersion: hasStoredContractVersion,
    );
  }

  @override
  Future<void> write(OnboardingStatus next) async {
    status = next;
    hasStoredContractVersion = true;
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

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  test(
      'O9B late owner failure keeps completion atomic and retry converges safely',
      () async {
    final profileRepo = _CountingUserProfileRepository();
    final bodyRepo = body_owner.InMemoryBodySetupRepository();
    final wellnessRepo = body_owner.InMemoryWellnessTargetsRepository();
    final nutritionProfileRepo =
        nutrition_owner.InMemoryNutritionProfileRepository();
    final workoutProfileRepo = workout_owner.InMemoryWorkoutProfileRepository();
    final workoutTargetsRepo = workout_owner.InMemoryWorkoutTargetsRepository();
    final nutritionTargetsRepo = _FailOnceNutritionTargetsRepository();

    final persistOwners = PersistOnboardingOwnerDataUseCase(
      profileRepository: profileRepo,
      bodyRepository: bodyRepo,
      wellnessRepository: wellnessRepo,
      nutritionProfileRepository: nutritionProfileRepo,
      workoutProfileRepository: workoutProfileRepo,
      workoutTargetsRepository: workoutTargetsRepo,
      nutritionTargetsRepository: nutritionTargetsRepo,
    );

    final draft = OnboardingDraft(
      status: OnboardingStatus.inProgress,
      selectedMode: AppMode.hybrid,
      workoutIntroChoice: WorkoutIntroChoice.setupNow,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.stayFit,
      ),
      currentStepId: OnboardingStepId.review,
      profile: _validProfile(),
      nutrition: const NutritionOnboardingDraft(
        dietType: NutritionDietType.vegetarian,
        allergyRestrictions: {NutritionAllergyRestriction.none},
      ),
      workout: _validWorkout(),
      targets: _validTargets(),
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.hybrid,
      workoutIntroChoice: WorkoutIntroChoice.setupNow,
    );

    final draftRepository = InMemoryOnboardingDraftRepository(
      initialSnapshot: OnboardingDraftSnapshot(draft: draft),
    );
    final modePreference = _FakeAppModePreference();
    final statusRepository = _FakeOnboardingStatusRepository();
    final completionRepository = _FakeCompletionRepository();

    final complete = CompleteOnboardingUseCase(
      confirmedModePreference: modePreference,
      statusRepository: statusRepository,
      persistOwnerDataUseCase: persistOwners,
      completionRepository: completionRepository,
      draftRepository: draftRepository,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    await expectLater(
      () => complete(draft: draft, flowPlan: flowPlan),
      throwsA(
        isA<OwnerPersistenceException>().having(
          (error) => error.owner,
          'owner',
          OwnerPersistenceTarget.nutritionTargets,
        ),
      ),
    );

    // Independent canonical tables are not rolled back. Upstream owner writes
    // remain durable/retry-safe, but onboarding completion must stay unpublished.
    expect(profileRepo.data?.name, 'Tio User');
    expect(bodyRepo.data, isNotNull);
    expect(wellnessRepo.data, isNotNull);
    expect(await nutritionProfileRepo.read(), isNotNull);
    expect(await workoutProfileRepo.read(), isNotNull);
    expect(await workoutTargetsRepo.read(), isNotNull);
    expect(await nutritionTargetsRepo.read(), isNull);
    expect(profileRepo.upsertCalls, 1);
    expect(nutritionTargetsRepo.upsertCalls, 1);

    expect(modePreference.storedMode, isNull);
    expect(completionRepository.markCalls, 0);
    expect(statusRepository.status, isNull);
    expect(await draftRepository.loadDraft(), isNotNull);

    await complete(draft: draft, flowPlan: flowPlan);

    // Retry replays idempotent owner upserts and converges to one canonical
    // final state before completion publication and draft cleanup.
    expect(profileRepo.upsertCalls, 2);
    expect(profileRepo.data?.name, 'Tio User');
    expect(bodyRepo.data?.currentWeightKg, 60);
    expect(wellnessRepo.data?.dailySteps, 10000);
    expect(await nutritionProfileRepo.read(), isNotNull);
    expect(await workoutProfileRepo.read(), isNotNull);
    expect(await workoutTargetsRepo.read(), isNotNull);
    expect(await nutritionTargetsRepo.read(), isNotNull);
    expect(nutritionTargetsRepo.upsertCalls, 2);

    expect(modePreference.storedMode, AppMode.hybrid);
    expect(completionRepository.markCalls, 1);
    expect(
      completionRepository.state,
      RemoteOnboardingCompletionState.completed,
    );
    expect(statusRepository.status, OnboardingStatus.completed);
    expect(await draftRepository.loadDraft(), isNull);
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

class _FailOnceNutritionTargetsRepository
    implements nutrition_owner.NutritionTargetsRepository {
  final nutrition_owner.InMemoryNutritionTargetsRepository _delegate =
      nutrition_owner.InMemoryNutritionTargetsRepository();

  int upsertCalls = 0;

  @override
  Future<nutrition_owner.NutritionTargetsData?> read() => _delegate.read();

  @override
  Future<void> upsert(nutrition_owner.NutritionTargetsData targets) async {
    upsertCalls++;
    if (upsertCalls == 1) {
      throw StateError('Nutrition Targets write failed once');
    }
    await _delegate.upsert(targets);
  }

  @override
  Future<void> updateAdditionalNutrientGoal(
    NutrientId nutrientId,
    nutrition_owner.AdditionalNutrientGoal? goal,
  ) =>
      _delegate.updateAdditionalNutrientGoal(nutrientId, goal);
}

class _FakeCompletionRepository implements OnboardingCompletionRepository {
  RemoteOnboardingCompletionState state =
      RemoteOnboardingCompletionState.incomplete;
  int markCalls = 0;

  @override
  Future<RemoteOnboardingCompletionState> readCurrent() async => state;

  @override
  Future<void> markCurrentCompleted() async {
    markCalls++;
    state = RemoteOnboardingCompletionState.completed;
  }
}

class _FakeAppModePreference implements AppModePreference {
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
  OnboardingStatus? status;
  bool hasStoredContractVersion = false;

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
      status: status,
      hasStoredContractVersion: hasStoredContractVersion,
    );
  }

  @override
  Future<void> write(OnboardingStatus status) async {
    this.status = status;
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
    targetWeightDirection: GoalWeightDirection.loss,
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

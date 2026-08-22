import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/src/domain/domain.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  late _FakeUserProfileRepository profileRepo;
  late body_owner.InMemoryBodySetupRepository bodyRepo;
  late workout_owner.InMemoryWorkoutPreferencesRepository workoutRepo;
  late nutrition_owner.InMemoryTargetsSetupRepository targetsRepo;
  late PersistOnboardingOwnerDataUseCase useCase;

  setUp(() {
    profileRepo = _FakeUserProfileRepository();
    bodyRepo = body_owner.InMemoryBodySetupRepository();
    workoutRepo = workout_owner.InMemoryWorkoutPreferencesRepository();
    targetsRepo = nutrition_owner.InMemoryTargetsSetupRepository();
    useCase = PersistOnboardingOwnerDataUseCase(
      profileRepository: profileRepo,
      bodyRepository: bodyRepo,
      workoutRepository: workoutRepo,
      targetsRepository: targetsRepo,
    );
  });

  group('PersistOnboardingOwnerDataUseCase mode-aware writes', () {
    test('workout mode persists common Profile, Body, Workout, and Targets',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );

      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        workoutIntroChoice: null,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(profileRepo.data?.name, 'Tio User');
      expect(profileRepo.data?.heightCm, 165);
      expect(bodyRepo.data, isNotNull);
      expect(bodyRepo.data?.currentWeightKg, 60);
      expect(await workoutRepo.getWorkoutPreferences(), isNotNull);
      expect(await targetsRepo.getTargetsSetup(), isNotNull);
    });

    test('nutrition mode persists common Profile, Body and Targets, not Workout',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );

      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(profileRepo.data, isNotNull);
      expect(bodyRepo.data, isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      expect(await targetsRepo.getTargetsSetup(), isNotNull);
    });

    test('hybrid setupNow persists common Profile, Body, Workout, and Targets',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );

      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(profileRepo.data, isNotNull);
      expect(bodyRepo.data, isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNotNull);
      expect(await targetsRepo.getTargetsSetup(), isNotNull);
    });

    test('hybrid later persists common Profile, Body and Targets, not Workout',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );

      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(profileRepo.data, isNotNull);
      expect(bodyRepo.data, isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      expect(await targetsRepo.getTargetsSetup(), isNotNull);
    });

    test('active weight goal remains Body/Targets-owned after Profile cutover',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        profile: _validProfile(),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(profileRepo.data, isNotNull);
      expect(
        bodyRepo.data?.activeGoal?.goalType,
        body_owner.BodyGoalType.loseWeight,
      );
      expect(bodyRepo.data?.activeGoal?.targetWeightKg, 58);
      expect(bodyRepo.data?.activeGoal?.weeklyWeightChangeKg, 0.5);
      expect(bodyRepo.data?.activeGoal?.intentRank, 1);
      expect((await targetsRepo.getTargetsSetup())?.targetWeightKg, 58);
      expect((await targetsRepo.getTargetsSetup())?.goalPaceKgPerWeek, 0.5);
    });

    test('ineligible goal keeps dormant Target Weight and pace out of Body owner',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        profile: _validProfile(),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(
        bodyRepo.data?.activeGoal?.goalType,
        body_owner.BodyGoalType.maintainWeight,
      );
      expect(bodyRepo.data?.activeGoal?.targetWeightKg, isNull);
      expect(bodyRepo.data?.activeGoal?.weeklyWeightChangeKg, isNull);
      expect(bodyRepo.data?.activeGoal?.intentRank, 1);
      expect((await targetsRepo.getTargetsSetup())?.targetWeightKg, isNull);
      expect((await targetsRepo.getTargetsSetup())?.goalPaceKgPerWeek, 0.0);
    });

    test('Profile failure stops before downstream owner writes', () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: _FailingUserProfileRepository(),
        bodyRepository: bodyRepo,
        workoutRepository: workoutRepo,
        targetsRepository: targetsRepo,
      );

      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );

      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        workoutIntroChoice: null,
      );

      await expectLater(
        () => failingUseCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (e) => e.owner,
            'owner',
            OwnerPersistenceTarget.profile,
          ),
        ),
      );

      expect(bodyRepo.data, isNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      expect(await targetsRepo.getTargetsSetup(), isNull);
    });

    test('missing required Profile answers fail as Profile owner error', () async {
      final invalidDraft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        profile: ProfileOnboardingDraft(name: 'Tio User'),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await expectLater(
        () => useCase(draft: invalidDraft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (e) => e.owner,
            'owner',
            OwnerPersistenceTarget.profile,
          ),
        ),
      );
      expect(bodyRepo.data, isNull);
    });

    test('re-throws OwnerPersistenceException when Body repository fails',
        () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: _FailingBodySetupRepository(),
        workoutRepository: workoutRepo,
        targetsRepository: targetsRepo,
      );

      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        profile: _validProfile(),
        targets: _validTargets(),
      );

      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await expectLater(
        () => failingUseCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (e) => e.owner,
            'owner',
            OwnerPersistenceTarget.body,
          ),
        ),
      );
      expect(profileRepo.data, isNotNull);
    });
  });
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

class _FailingUserProfileRepository
    implements profile_owner.UserProfileRepository {
  @override
  Future<profile_owner.UserProfileData?> read() async => null;

  @override
  Future<void> upsert(profile_owner.UserProfileData profile) async {
    throw StateError('Profile database write failed');
  }
}

class _FailingBodySetupRepository implements body_owner.BodySetupRepository {
  @override
  Future<void> saveBodySetup(body_owner.BodySetupData data) async {
    throw StateError('Body database write failed');
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

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
  late body_owner.InMemoryWellnessTargetsRepository wellnessRepo;
  late nutrition_owner.InMemoryNutritionProfileRepository nutritionProfileRepo;
  late workout_owner.InMemoryWorkoutPreferencesRepository workoutRepo;
  late nutrition_owner.InMemoryNutritionTargetsRepository nutritionTargetsRepo;
  late PersistOnboardingOwnerDataUseCase useCase;

  setUp(() {
    profileRepo = _FakeUserProfileRepository();
    bodyRepo = body_owner.InMemoryBodySetupRepository();
    wellnessRepo = body_owner.InMemoryWellnessTargetsRepository();
    nutritionProfileRepo = nutrition_owner.InMemoryNutritionProfileRepository();
    workoutRepo = workout_owner.InMemoryWorkoutPreferencesRepository();
    nutritionTargetsRepo = nutrition_owner.InMemoryNutritionTargetsRepository();
    useCase = PersistOnboardingOwnerDataUseCase(
      profileRepository: profileRepo,
      bodyRepository: bodyRepo,
      wellnessRepository: wellnessRepo,
      nutritionProfileRepository: nutritionProfileRepo,
      workoutRepository: workoutRepo,
      nutritionTargetsRepository: nutritionTargetsRepo,
    );
  });

  Future<nutrition_owner.NutritionProfileData?> canonicalNutritionProfile() {
    return nutritionProfileRepo.read();
  }

  Future<nutrition_owner.NutritionTargetsData?> canonicalNutritionTargets() {
    return nutritionTargetsRepo.read();
  }

  group('PersistOnboardingOwnerDataUseCase canonical owner writes', () {
    test(
        'workout writes Profile Body Wellness Workout and canonical Nutrition Targets only',
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
      expect(bodyRepo.data?.currentWeightKg, 60);
      expect(wellnessRepo.data?.dailySteps, 10000);
      expect(wellnessRepo.data?.waterMl, 2500);
      expect(await workoutRepo.getWorkoutPreferences(), isNotNull);
      expect(await canonicalNutritionProfile(), isNull);
      expect(await canonicalNutritionTargets(), isNotNull);
    });

    test(
        'nutrition writes canonical Nutrition Profile and Targets but not Workout',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        profile: _validProfile(),
        nutrition: const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegan,
          allergyRestrictions: {NutritionAllergyRestriction.none},
        ),
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
      expect(wellnessRepo.data, isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      final nutritionProfile = await canonicalNutritionProfile();
      expect(nutritionProfile, isNotNull);
      expect(nutritionProfile?.preferredDiet, 'vegan');
      expect(nutritionProfile?.allergies, isEmpty);
      expect(nutritionProfile?.dislikedFoods, isNull);
      expect(nutritionProfile?.medicalConditions, isNull);
      expect(await canonicalNutritionTargets(), isNotNull);
    });

    test('hybrid setupNow writes both canonical Nutrition owners and Workout',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        profile: _validProfile(),
        nutrition: const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegetarian,
          allergyRestrictions: {NutritionAllergyRestriction.gluten},
        ),
        workout: _validWorkout(),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(await canonicalNutritionProfile(), isNotNull);
      expect(await canonicalNutritionTargets(), isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNotNull);
    });

    test('hybrid later writes both canonical Nutrition owners but not Workout',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        profile: _validProfile(),
        nutrition: const NutritionOnboardingDraft(
          dietType: NutritionDietType.nonVegetarian,
          allergyRestrictions: {NutritionAllergyRestriction.nuts},
        ),
        workout: _validWorkout(),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(await canonicalNutritionProfile(), isNotNull);
      expect(await canonicalNutritionTargets(), isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
    });

    test('active weight goal remains Body-owned while canonical targets are outputs only',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        profile: _validProfile(),
        nutrition: const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegetarian,
          allergyRestrictions: {NutritionAllergyRestriction.none},
        ),
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
        body_owner.BodyGoalType.loseWeight,
      );
      expect(bodyRepo.data?.activeGoal?.targetWeightKg, 58);
      expect(bodyRepo.data?.activeGoal?.weeklyWeightChangeKg, 0.5);
      final nutritionTargets = await canonicalNutritionTargets();
      expect(nutritionTargets, isNotNull);
      expect(
        nutritionTargets?.customizationState,
        nutrition_owner.NutritionTargetCustomizationState.recommended,
      );
      expect(nutritionTargets?.recommendationMetadata['source'], 'onboarding');
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
      expect(await canonicalNutritionTargets(), isNotNull);
    });

    test('Profile failure stops every downstream canonical owner', () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: _FailingUserProfileRepository(),
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutRepository: workoutRepo,
        nutritionTargetsRepository: nutritionTargetsRepo,
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
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.profile,
          ),
        ),
      );

      expect(bodyRepo.data, isNull);
      expect(wellnessRepo.data, isNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      expect(await canonicalNutritionProfile(), isNull);
      expect(await canonicalNutritionTargets(), isNull);
    });

    test('Body failure stops Wellness and both later Nutrition owners', () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: _FailingBodySetupRepository(),
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutRepository: workoutRepo,
        nutritionTargetsRepository: nutritionTargetsRepo,
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
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
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.body,
          ),
        ),
      );

      expect(profileRepo.data, isNotNull);
      expect(wellnessRepo.data, isNull);
      expect(await canonicalNutritionProfile(), isNull);
      expect(await canonicalNutritionTargets(), isNull);
    });

    test('Wellness failure stops Nutrition Profile Workout and Targets', () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: _FailingWellnessTargetsRepository(),
        nutritionProfileRepository: nutritionProfileRepo,
        workoutRepository: workoutRepo,
        nutritionTargetsRepository: nutritionTargetsRepo,
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        profile: _validProfile(),
        nutrition: const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegan,
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

      await expectLater(
        () => failingUseCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.wellness,
          ),
        ),
      );

      expect(await canonicalNutritionProfile(), isNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      expect(await canonicalNutritionTargets(), isNull);
    });

    test('Nutrition Profile failure stops Workout and Nutrition Targets', () async {
      final failingTargets = nutrition_owner.InMemoryNutritionTargetsRepository();
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: _FailingNutritionProfileRepository(),
        workoutRepository: workoutRepo,
        nutritionTargetsRepository: failingTargets,
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        profile: _validProfile(),
        nutrition: const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegan,
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

      await expectLater(
        () => failingUseCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.nutritionProfile,
          ),
        ),
      );

      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      expect(await failingTargets.read(), isNull);
    });

    test('Workout failure blocks canonical Nutrition Targets', () async {
      final canonicalTargets = nutrition_owner.InMemoryNutritionTargetsRepository();
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutRepository: _FailingWorkoutRepository(),
        nutritionTargetsRepository: canonicalTargets,
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
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.workout,
          ),
        ),
      );
      expect(await canonicalTargets.read(), isNull);
    });

    test('Nutrition Targets failure is reported at canonical owner boundary',
        () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutRepository: workoutRepo,
        nutritionTargetsRepository: _FailingNutritionTargetsRepository(),
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
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.nutritionTargets,
          ),
        ),
      );
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

class _FailingWellnessTargetsRepository
    implements body_owner.WellnessTargetsRepository {
  @override
  Future<body_owner.WellnessTargetsData?> read() async => null;

  @override
  Future<void> upsert(body_owner.WellnessTargetsData targets) async {
    throw StateError('Wellness database write failed');
  }
}

class _FailingNutritionProfileRepository
    implements nutrition_owner.NutritionProfileRepository {
  @override
  Future<nutrition_owner.NutritionProfileData?> read() async => null;

  @override
  Future<void> upsert(nutrition_owner.NutritionProfileData profile) async {
    throw StateError('Nutrition Profile database write failed');
  }
}

class _FailingWorkoutRepository
    implements workout_owner.WorkoutPreferencesRepository {
  @override
  Future<workout_owner.WorkoutPreferencesData?> getWorkoutPreferences() async =>
      null;

  @override
  Future<void> saveWorkoutPreferences(
    workout_owner.WorkoutPreferencesData data,
  ) async {
    throw StateError('Workout database write failed');
  }
}

class _FailingNutritionTargetsRepository
    implements nutrition_owner.NutritionTargetsRepository {
  @override
  Future<nutrition_owner.NutritionTargetsData?> read() async => null;

  @override
  Future<void> upsert(nutrition_owner.NutritionTargetsData targets) async {
    throw StateError('Nutrition Targets database write failed');
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

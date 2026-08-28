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
  late workout_owner.InMemoryWorkoutProfileRepository workoutProfileRepo;
  late workout_owner.InMemoryWorkoutTargetsRepository workoutTargetsRepo;
  late nutrition_owner.InMemoryNutritionTargetsRepository nutritionTargetsRepo;
  late PersistOnboardingOwnerDataUseCase useCase;

  setUp(() {
    profileRepo = _FakeUserProfileRepository();
    bodyRepo = body_owner.InMemoryBodySetupRepository();
    wellnessRepo = body_owner.InMemoryWellnessTargetsRepository();
    nutritionProfileRepo = nutrition_owner.InMemoryNutritionProfileRepository();
    workoutProfileRepo = workout_owner.InMemoryWorkoutProfileRepository();
    workoutTargetsRepo = workout_owner.InMemoryWorkoutTargetsRepository();
    nutritionTargetsRepo = nutrition_owner.InMemoryNutritionTargetsRepository();
    useCase = PersistOnboardingOwnerDataUseCase(
      profileRepository: profileRepo,
      bodyRepository: bodyRepo,
      wellnessRepository: wellnessRepo,
      nutritionProfileRepository: nutritionProfileRepo,
      workoutProfileRepository: workoutProfileRepo,
      workoutTargetsRepository: workoutTargetsRepo,
      nutritionTargetsRepository: nutritionTargetsRepo,
    );
  });

  Future<nutrition_owner.NutritionProfileData?> canonicalNutritionProfile() {
    return nutritionProfileRepo.read();
  }

  Future<nutrition_owner.NutritionTargetsData?> canonicalNutritionTargets() {
    return nutritionTargetsRepo.read();
  }

  Future<workout_owner.WorkoutProfileData?> canonicalWorkoutProfile() {
    return workoutProfileRepo.read();
  }

  Future<workout_owner.WorkoutTargetsData?> canonicalWorkoutTargets() {
    return workoutTargetsRepo.read();
  }

  group('PersistOnboardingOwnerDataUseCase canonical owner writes', () {
    test('workout writes only canonical Body and Workout owners', () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(profileRepo.data?.name, 'Tio User');
      expect(bodyRepo.data?.currentWeightKg, 60);
      expect(wellnessRepo.data, isNull);

      final workoutProfile = await canonicalWorkoutProfile();
      expect(workoutProfile, isNotNull);
      expect(
          workoutProfile?.workoutLocation, workout_owner.WorkoutGymAccess.gym);
      expect(
        workoutProfile?.experienceLevel,
        workout_owner.WorkoutExperienceLevel.intermediate,
      );
      expect(workoutProfile?.focusAreas,
          {workout_owner.WorkoutFocusArea.fullBody});

      final workoutTargets = await canonicalWorkoutTargets();
      expect(workoutTargets, isNotNull);
      expect(
        workoutTargets?.primaryWorkoutGoal,
        workout_owner.WorkoutTargetGoal.stayFit,
      );
      expect(workoutTargets?.primaryGoalRank, 1);
      expect(workoutTargets?.preferredDurationMins, 60);
      expect(
          workoutTargets?.splitProgram, workout_owner.WorkoutSplit.upperLower);

      expect(await canonicalNutritionProfile(), isNull);
      expect(await canonicalNutritionTargets(), isNull);
    });

    test('nutrition writes Nutrition owners and no canonical Workout owner',
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
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(profileRepo.data, isNotNull);
      expect(bodyRepo.data, isNotNull);
      expect(wellnessRepo.data, isNotNull);
      expect(await canonicalWorkoutProfile(), isNull);
      expect(await canonicalWorkoutTargets(), isNull);

      final nutritionProfile = await canonicalNutritionProfile();
      expect(nutritionProfile, isNotNull);
      expect(nutritionProfile?.preferredDiet, 'vegan');
      expect(nutritionProfile?.allergies, isEmpty);
      expect(nutritionProfile?.dislikedFoods, isNull);
      expect(nutritionProfile?.medicalConditions, isNull);
      expect(await canonicalNutritionTargets(), isNotNull);
    });

    test(
        'nutrition with blank optional Health Other successfully persists normalized Profile and reaches Nutrition owners',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        profile: _validProfile().copyWith(
          healthConditions: const {ProfileHealthCondition.other},
          otherHealthCondition: '   ',
        ),
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
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(profileRepo.data, isNotNull);
      expect(
        profileRepo.data?.healthConditions,
        {profile_owner.ProfileHealthCondition.other},
      );
      expect(profileRepo.data?.otherHealthCondition, isNull);
      expect(bodyRepo.data, isNotNull);
      expect(wellnessRepo.data, isNotNull);

      final nutritionProfile = await canonicalNutritionProfile();
      expect(nutritionProfile, isNotNull);
      expect(nutritionProfile?.preferredDiet, 'vegan');
      expect(await canonicalNutritionTargets(), isNotNull);
    });

    test('hybrid setupNow writes Nutrition plus both canonical Workout owners',
        () async {
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.getStronger,
        ),
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
      expect(await canonicalWorkoutProfile(), isNotNull);
      final workoutTargets = await canonicalWorkoutTargets();
      expect(workoutTargets, isNotNull);
      expect(workoutTargets?.primaryGoalRank, 1);
      expect(workoutTargets?.supportingGoalRank, 2);
      expect(await canonicalNutritionTargets(), isNotNull);
    });

    test(
        'hybrid later preserves draft but writes neither canonical Workout owner',
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
      expect(await canonicalWorkoutProfile(), isNull);
      expect(await canonicalWorkoutTargets(), isNull);
      expect(draft.workout.trainingDays, isNotEmpty);
    });

    test(
        'active weight goal remains Body-owned while canonical targets are outputs only',
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

    test('Profile failure stops every downstream canonical owner', () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: _FailingUserProfileRepository(),
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutProfileRepository: workoutProfileRepo,
        workoutTargetsRepository: workoutTargetsRepo,
        nutritionTargetsRepository: nutritionTargetsRepo,
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection:
            const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
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
      expect(await canonicalNutritionProfile(), isNull);
      expect(await canonicalWorkoutProfile(), isNull);
      expect(await canonicalWorkoutTargets(), isNull);
      expect(await canonicalNutritionTargets(), isNull);
    });

    test('Wellness failure stops Nutrition Profile and both Workout owners',
        () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: _FailingWellnessTargetsRepository(),
        nutritionProfileRepository: nutritionProfileRepo,
        workoutProfileRepository: workoutProfileRepo,
        workoutTargetsRepository: workoutTargetsRepo,
        nutritionTargetsRepository: nutritionTargetsRepo,
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        goalSelection:
            const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
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
      expect(await canonicalWorkoutProfile(), isNull);
      expect(await canonicalWorkoutTargets(), isNull);
      expect(await canonicalNutritionTargets(), isNull);
    });

    test(
        'Nutrition Profile failure stops both Workout owners and Nutrition Targets',
        () async {
      final failingTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: _FailingNutritionProfileRepository(),
        workoutProfileRepository: workoutProfileRepo,
        workoutTargetsRepository: workoutTargetsRepo,
        nutritionTargetsRepository: failingTargets,
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        goalSelection:
            const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
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

      expect(await canonicalWorkoutProfile(), isNull);
      expect(await canonicalWorkoutTargets(), isNull);
      expect(await failingTargets.read(), isNull);
    });

    test('Workout Profile failure blocks Workout Targets and Nutrition Targets',
        () async {
      final canonicalTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutProfileRepository: _FailingWorkoutProfileRepository(),
        workoutTargetsRepository: workoutTargetsRepo,
        nutritionTargetsRepository: canonicalTargets,
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection:
            const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );

      await expectLater(
        () => failingUseCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.workoutProfile,
          ),
        ),
      );

      expect(await canonicalWorkoutTargets(), isNull);
      expect(await canonicalTargets.read(), isNull);
    });

    test(
        'Workout Targets failure reports its owner and blocks Nutrition Targets',
        () async {
      final canonicalTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutProfileRepository: workoutProfileRepo,
        workoutTargetsRepository: _FailingWorkoutTargetsRepository(),
        nutritionTargetsRepository: canonicalTargets,
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection:
            const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: _validTargets(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );

      await expectLater(
        () => failingUseCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.workoutTargets,
          ),
        ),
      );

      expect(await canonicalWorkoutProfile(), isNotNull);
      expect(await canonicalTargets.read(), isNull);
    });

    test('Nutrition Targets failure is reported at canonical owner boundary',
        () async {
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: profileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutProfileRepository: workoutProfileRepo,
        workoutTargetsRepository: workoutTargetsRepo,
        nutritionTargetsRepository: _FailingNutritionTargetsRepository(),
      );
      final draft = OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        goalSelection:
            const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
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
            OwnerPersistenceTarget.nutritionTargets,
          ),
        ),
      );

      expect(await canonicalWorkoutProfile(), isNotNull);
      expect(await canonicalWorkoutTargets(), isNotNull);
    });
  });
}

class _FakeUserProfileRepository
    implements profile_owner.UserProfileRepository {
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

class _FailingWorkoutProfileRepository
    implements workout_owner.WorkoutProfileRepository {
  @override
  Future<workout_owner.WorkoutProfileData?> read() async => null;

  @override
  Future<void> upsert(workout_owner.WorkoutProfileData profile) async {
    throw StateError('Workout Profile database write failed');
  }
}

class _FailingWorkoutTargetsRepository
    implements workout_owner.WorkoutTargetsRepository {
  @override
  Future<workout_owner.WorkoutTargetsData?> read() async => null;

  @override
  Future<void> upsert(workout_owner.WorkoutTargetsData targets) async {
    throw StateError('Workout Targets database write failed');
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

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  group('O6E integrated canonical Workout acceptance', () {
    test('Hybrid later preserves pre-existing canonical Workout owners',
        () async {
      final workoutProfile = workout_owner.InMemoryWorkoutProfileRepository();
      final workoutTargets = workout_owner.InMemoryWorkoutTargetsRepository();
      final nutritionProfile =
          nutrition_owner.InMemoryNutritionProfileRepository();
      final nutritionTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();

      await workoutProfile.upsert(
        const workout_owner.WorkoutProfileData(
          workoutLocation: workout_owner.WorkoutGymAccess.home,
          availableEquipment: {workout_owner.WorkoutEquipment.mat},
          experienceLevel: workout_owner.WorkoutExperienceLevel.advanced,
          focusAreas: {workout_owner.WorkoutFocusArea.legs},
          healthConcerns: {'Existing knee note'},
        ),
      );
      await workoutTargets.upsert(
        const workout_owner.WorkoutTargetsData(
          primaryWorkoutGoal: workout_owner.WorkoutTargetGoal.stayFit,
          primaryGoalRank: 1,
          trainingDays: {workout_owner.WorkoutTrainingDay.saturday},
          preferredDurationMins: 30,
          splitProgram: workout_owner.WorkoutSplit.fullBody,
          specialEvent: 'Existing race',
        ),
      );

      final persist = PersistOnboardingOwnerDataUseCase(
        profileRepository: _MemoryUserProfileRepository(),
        bodyRepository: body_owner.InMemoryBodySetupRepository(),
        wellnessRepository: body_owner.InMemoryWellnessTargetsRepository(),
        nutritionProfileRepository: nutritionProfile,
        workoutProfileRepository: workoutProfile,
        workoutTargetsRepository: workoutTargets,
        nutritionTargetsRepository: nutritionTargets,
      );
      final draft = _validDraft(
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );

      expect(
        flowPlan.stepIds,
        isNot(contains(OnboardingStepId.workoutProfile)),
      );
      expect(
        flowPlan.stepIds,
        isNot(contains(OnboardingStepId.workoutTargets)),
      );

      await persist(draft: draft, flowPlan: flowPlan);

      final preservedProfile = await workoutProfile.read();
      expect(
        preservedProfile?.workoutLocation,
        workout_owner.WorkoutGymAccess.home,
      );
      expect(
        preservedProfile?.availableEquipment,
        {workout_owner.WorkoutEquipment.mat},
      );
      expect(
        preservedProfile?.experienceLevel,
        workout_owner.WorkoutExperienceLevel.advanced,
      );
      expect(
        preservedProfile?.focusAreas,
        {workout_owner.WorkoutFocusArea.legs},
      );
      expect(preservedProfile?.healthConcerns, {'Existing knee note'});

      final preservedTargets = await workoutTargets.read();
      expect(
        preservedTargets?.primaryWorkoutGoal,
        workout_owner.WorkoutTargetGoal.stayFit,
      );
      expect(preservedTargets?.primaryGoalRank, 1);
      expect(
        preservedTargets?.trainingDays,
        {workout_owner.WorkoutTrainingDay.saturday},
      );
      expect(preservedTargets?.preferredDurationMins, 30);
      expect(
        preservedTargets?.splitProgram,
        workout_owner.WorkoutSplit.fullBody,
      );
      expect(preservedTargets?.specialEvent, 'Existing race');
      expect(preservedTargets?.specialEventDate, isNull);

      expect(await nutritionProfile.read(), isNotNull);
      expect(await nutritionTargets.read(), isNotNull);

      // The active run skipped Workout without deleting the dormant draft.
      expect(draft.workout.gymAccess, WorkoutGymAccess.gym);
      expect(draft.workout.trainingDays, isNotEmpty);
    });

    test(
        'Workout Targets failure blocks publication, retry succeeds canonically, and completed retry is idempotent',
        () async {
      final operations = <String>[];
      final profile = _RecordingProfileRepository(operations);
      final body = _RecordingBodyRepository(operations);
      final wellness = _RecordingWellnessRepository(operations);
      final nutritionProfile = _RecordingNutritionProfileRepository(operations);
      final workoutProfile = _RecordingWorkoutProfileRepository(operations);
      final workoutTargets = _RecordingWorkoutTargetsRepository(
        operations,
        failuresRemaining: 1,
      );
      final nutritionTargets = _RecordingNutritionTargetsRepository(operations);
      final appPreferences = _RecordingAppPreferencesRepository(operations);
      final preference = _RecordingAppModePreference(operations);
      final status = _RecordingOnboardingStatusRepository(operations);

      final complete = CompleteOnboardingUseCase(
        confirmedModePreference: preference,
        appPreferencesRepository: appPreferences,
        statusRepository: status,
        persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
          profileRepository: profile,
          bodyRepository: body,
          wellnessRepository: wellness,
          nutritionProfileRepository: nutritionProfile,
          workoutProfileRepository: workoutProfile,
          workoutTargetsRepository: workoutTargets,
          nutritionTargetsRepository: nutritionTargets,
        ),
        validator: const OnboardingCompletionValidator(
          hasDurableOwnerPersistence: true,
          backendUserReady: true,
        ),
      );
      final draft = _validDraft(
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
      );

      await expectLater(
        () => complete(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.workoutTargets,
          ),
        ),
      );

      expect(
        operations,
        [
          'status.ensureInitialized',
          'profile.upsert',
          'body.save',
          'wellness.upsert',
          'nutritionProfile.upsert',
          'workoutProfile.upsert',
          'workoutTargets.upsert',
        ],
      );
      expect(nutritionTargets.upsertCalls, 0);
      expect(appPreferences.upsertCalls, 0);
      expect(preference.writeCalls, 0);
      expect(status.completedWriteCalls, 0);

      await complete(draft: draft, flowPlan: flowPlan);

      expect(workoutProfile.upsertCalls, 2);
      expect(workoutTargets.upsertCalls, 2);
      expect(nutritionTargets.upsertCalls, 1);
      expect(appPreferences.upsertCalls, 1);
      expect(preference.writeCalls, 1);
      expect(status.completedWriteCalls, 1);
      expect(status.status, OnboardingStatus.completed);

      final storedProfile = await workoutProfile.read();
      expect(
        storedProfile?.workoutLocation,
        workout_owner.WorkoutGymAccess.gym,
      );
      expect(
        storedProfile?.experienceLevel,
        workout_owner.WorkoutExperienceLevel.intermediate,
      );
      expect(
        storedProfile?.focusAreas,
        {workout_owner.WorkoutFocusArea.fullBody},
      );
      expect(storedProfile?.healthConcerns, {'Knee'});

      final storedTargets = await workoutTargets.read();
      expect(
        storedTargets?.primaryWorkoutGoal,
        workout_owner.WorkoutTargetGoal.buildMuscle,
      );
      // Canonical Workout ranks are owner-relative after Body intents are filtered.
      expect(storedTargets?.primaryGoalRank, 1);
      expect(storedTargets?.supportingWorkoutGoal, isNull);
      expect(storedTargets?.supportingGoalRank, isNull);
      expect(
        storedTargets?.trainingDays,
        {
          workout_owner.WorkoutTrainingDay.monday,
          workout_owner.WorkoutTrainingDay.thursday,
        },
      );
      expect(storedTargets?.preferredDurationMins, 60);
      expect(
        storedTargets?.splitProgram,
        workout_owner.WorkoutSplit.upperLower,
      );
      expect(storedTargets?.specialEvent, 'Local race');
      expect(storedTargets?.specialEventDate, isNull);

      expect(
        operations.sublist(7),
        [
          'status.ensureInitialized',
          'profile.upsert',
          'body.save',
          'wellness.upsert',
          'nutritionProfile.upsert',
          'workoutProfile.upsert',
          'workoutTargets.upsert',
          'nutritionTargets.upsert',
          'appPreferences.upsert.hybrid',
          'mode.write.hybrid',
          'status.write.completed',
        ],
      );

      final operationsAfterCompletion = List<String>.of(operations);
      await complete(draft: draft, flowPlan: flowPlan);

      expect(operations, operationsAfterCompletion);
      expect(workoutProfile.upsertCalls, 2);
      expect(workoutTargets.upsertCalls, 2);
      expect(nutritionTargets.upsertCalls, 1);
      expect(appPreferences.upsertCalls, 1);
      expect(preference.writeCalls, 1);
      expect(status.completedWriteCalls, 1);
    });
  });
}

OnboardingDraft _validDraft({
  required AppMode mode,
  WorkoutIntroChoice? workoutIntroChoice,
}) {
  return OnboardingDraft(
    status: OnboardingStatus.inProgress,
    selectedMode: mode,
    workoutIntroChoice: workoutIntroChoice,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
      supportingGoal: GoalIntent.buildMuscle,
    ),
    currentStepId: OnboardingStepId.review,
    profile: ProfileOnboardingDraft(
      name: 'O6E User',
      gender: ProfileGender.female,
      dateOfBirth: DateTime(1996, 6, 15),
      heightCm: 165,
      currentWeightKg: 60,
      targetWeightKg: 56,
      targetWeightDirection: GoalWeightDirection.loss,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {ProfileHealthCondition.none},
    ),
    nutrition: const NutritionOnboardingDraft(
      dietType: NutritionDietType.vegetarian,
      allergyRestrictions: {NutritionAllergyRestriction.none},
    ),
    workout: const WorkoutOnboardingDraft(
      gymAccess: WorkoutGymAccess.gym,
      equipment: {},
      experienceLevel: WorkoutExperienceLevel.intermediate,
      focusAreas: {WorkoutFocusArea.fullBody},
      healthConcerns: '  Knee  ',
      trainingDays: {
        WorkoutTrainingDay.monday,
        WorkoutTrainingDay.thursday,
      },
      workoutDuration: WorkoutDuration.sixtyMinutes,
      workoutSplit: WorkoutSplit.upperLower,
      specialEvent: '  Local race  ',
    ),
    targets: const TargetsOnboardingDraft(
      dailySteps: 10000,
      sleepTargetMinutes: 480,
      sleepTimeMinutes: 1320,
      wakeTimeMinutes: 360,
      waterMl: 2500,
      goalPaceKgPerWeek: 0.5,
    ),
  );
}

class _MemoryUserProfileRepository
    implements profile_owner.UserProfileRepository {
  profile_owner.UserProfileData? data;

  @override
  Future<profile_owner.UserProfileData?> read() async => data;

  @override
  Future<void> upsert(profile_owner.UserProfileData profile) async {
    data = profile;
  }
}

class _RecordingProfileRepository
    implements profile_owner.UserProfileRepository {
  _RecordingProfileRepository(this.operations);

  final List<String> operations;
  profile_owner.UserProfileData? data;

  @override
  Future<profile_owner.UserProfileData?> read() async => data;

  @override
  Future<void> upsert(profile_owner.UserProfileData profile) async {
    operations.add('profile.upsert');
    data = profile;
  }
}

class _RecordingBodyRepository implements body_owner.BodySetupRepository {
  _RecordingBodyRepository(this.operations);

  final List<String> operations;

  @override
  Future<void> saveBodySetup(body_owner.BodySetupData data) async {
    operations.add('body.save');
  }
}

class _RecordingWellnessRepository
    implements body_owner.WellnessTargetsRepository {
  _RecordingWellnessRepository(this.operations);

  final List<String> operations;
  body_owner.WellnessTargetsData? data;

  @override
  Future<body_owner.WellnessTargetsData?> read() async => data;

  @override
  Future<void> upsert(body_owner.WellnessTargetsData targets) async {
    operations.add('wellness.upsert');
    data = targets;
  }
}

class _RecordingNutritionProfileRepository
    implements nutrition_owner.NutritionProfileRepository {
  _RecordingNutritionProfileRepository(this.operations);

  final List<String> operations;
  nutrition_owner.NutritionProfileData? data;

  @override
  Future<nutrition_owner.NutritionProfileData?> read() async => data;

  @override
  Future<void> upsert(nutrition_owner.NutritionProfileData profile) async {
    operations.add('nutritionProfile.upsert');
    data = profile;
  }
}

class _RecordingWorkoutProfileRepository
    implements workout_owner.WorkoutProfileRepository {
  _RecordingWorkoutProfileRepository(this.operations);

  final List<String> operations;
  int upsertCalls = 0;
  workout_owner.WorkoutProfileData? data;

  @override
  Future<workout_owner.WorkoutProfileData?> read() async => data;

  @override
  Future<void> upsert(workout_owner.WorkoutProfileData profile) async {
    upsertCalls += 1;
    operations.add('workoutProfile.upsert');
    data = profile;
  }
}

class _RecordingWorkoutTargetsRepository
    implements workout_owner.WorkoutTargetsRepository {
  _RecordingWorkoutTargetsRepository(
    this.operations, {
    this.failuresRemaining = 0,
  });

  final List<String> operations;
  int failuresRemaining;
  int upsertCalls = 0;
  workout_owner.WorkoutTargetsData? data;

  @override
  Future<workout_owner.WorkoutTargetsData?> read() async => data;

  @override
  Future<void> upsert(workout_owner.WorkoutTargetsData targets) async {
    upsertCalls += 1;
    operations.add('workoutTargets.upsert');
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw StateError('canonical Workout Targets write failed');
    }
    targets.validate();
    data = targets;
  }
}

class _RecordingNutritionTargetsRepository
    implements nutrition_owner.NutritionTargetsRepository {
  _RecordingNutritionTargetsRepository(this.operations);

  final List<String> operations;
  int upsertCalls = 0;
  nutrition_owner.NutritionTargetsData? data;

  @override
  Future<nutrition_owner.NutritionTargetsData?> read() async => data;

  @override
  Future<void> upsert(nutrition_owner.NutritionTargetsData targets) async {
    upsertCalls += 1;
    operations.add('nutritionTargets.upsert');
    targets.validate();
    data = targets;
  }

  @override
  Future<void> updateAdditionalNutrientGoal(
    NutrientId nutrientId,
    nutrition_owner.AdditionalNutrientGoal? goal,
  ) async {
    // Onboarding never configures Additional Nutrient Goals. Failing loudly
    // keeps that boundary honest if it ever changes.
    throw UnsupportedError(
        'Onboarding does not write Additional Nutrient Goals.');
  }
}

class _RecordingAppPreferencesRepository implements AppPreferencesRepository {
  _RecordingAppPreferencesRepository(this.operations);

  final List<String> operations;
  AppPreferencesState state = const AppPreferencesState.missing();
  int upsertCalls = 0;

  @override
  Future<AppPreferencesState> read() async => state;

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    upsertCalls += 1;
    operations.add('appPreferences.upsert.${preferences.appMode.storageValue}');
    state = AppPreferencesState.present(
      appMode: preferences.appMode,
      activeTabs: preferences.activeTabs,
    );
  }
}

class _RecordingAppModePreference implements AppModePreference {
  _RecordingAppModePreference(this.operations);

  final List<String> operations;
  AppMode? storedMode;
  int writeCalls = 0;

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
    writeCalls += 1;
    storedMode = mode;
    operations.add('mode.write.${mode.storageValue}');
  }

  @override
  Future<void> clear() async {
    storedMode = null;
  }
}

class _RecordingOnboardingStatusRepository
    implements OnboardingStatusRepository {
  _RecordingOnboardingStatusRepository(this.operations);

  final List<String> operations;
  OnboardingStatus? status;
  bool initialized = false;
  int completedWriteCalls = 0;

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return OnboardingStatusSnapshot(
      status: status,
      hasStoredContractVersion: initialized || status != null,
    );
  }

  @override
  Future<void> ensureInitialized() async {
    initialized = true;
    operations.add('status.ensureInitialized');
  }

  @override
  Future<void> write(OnboardingStatus value) async {
    status = value;
    if (value == OnboardingStatus.completed) {
      completedWriteCalls += 1;
    }
    operations.add('status.write.${value.name}');
  }

  @override
  Future<void> clear() async {
    status = null;
    initialized = false;
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  group('O4D integrated canonical Wellness acceptance', () {
    test(
        'fresh Wellness values persist losslessly while Nutrition only consumes calculation inputs',
        () async {
      final wellness = body_owner.InMemoryWellnessTargetsRepository();
      final nutritionTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final persist = PersistOnboardingOwnerDataUseCase(
        profileRepository: _MemoryUserProfileRepository(),
        bodyRepository: body_owner.InMemoryBodySetupRepository(),
        wellnessRepository: wellness,
        nutritionProfileRepository:
            nutrition_owner.InMemoryNutritionProfileRepository(),
        workoutProfileRepository:
            workout_owner.InMemoryWorkoutProfileRepository(),
        workoutTargetsRepository:
            workout_owner.InMemoryWorkoutTargetsRepository(),
        nutritionTargetsRepository: nutritionTargets,
      );
      final draft = _draft(
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.nutritionTarget,
          dailySteps: 12345,
          sleepTargetMinutes: 465,
          sleepTimeMinutes: 1375,
          wakeTimeMinutes: 395,
          waterMl: 2875,
          goalPaceKgPerWeek: 0.5,
        ),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await persist(draft: draft, flowPlan: flowPlan);

      expect(
        await wellness.read(),
        const body_owner.WellnessTargetsData(
          dailySteps: 12345,
          waterMl: 2875,
          sleepTargetMinutes: 465,
          bedTimeMinutes: 1375,
          wakeTimeMinutes: 395,
        ),
      );

      // Nutrition can consume Wellness inputs for recommendation calculation,
      // but the canonical Nutrition Targets owner stores outputs only and has
      // no Wellness mirror fields.
      final calculatedTargets = await nutritionTargets.read();
      expect(calculatedTargets, isNotNull);
      expect(calculatedTargets?.caloriesKcal, isNotNull);
      expect(calculatedTargets?.recommendationMetadata['source'], 'onboarding');
    });

    test(
        'legacy missing Wellness fields keep later resume and persist canonical unknowns, not UI defaults',
        () async {
      const snapshotMapper = OnboardingDraftSnapshotDtoMapper();
      final sourceJson = snapshotMapper.toJson(
        OnboardingDraftSnapshot(
          draft: _draft(
            targets: const TargetsOnboardingDraft(
              currentStepId: TargetStepId.nutritionTarget,
            ),
          ),
        ),
      );
      sourceJson['schema_version'] = 2;
      sourceJson['current_step_id'] = 'review';
      final targetsJson = sourceJson['targets'] as Map<String, dynamic>;
      targetsJson
        ..remove('daily_steps')
        ..remove('sleep_target_minutes')
        ..remove('sleep_time_minutes')
        ..remove('wake_time_minutes')
        ..remove('water_ml')
        ..remove('daily_steps_known')
        ..remove('sleep_target_minutes_known')
        ..remove('sleep_time_minutes_known')
        ..remove('wake_time_minutes_known')
        ..remove('water_ml_known');

      final restored = snapshotMapper.fromJson(sourceJson);
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: restored.draft,
      );
      addTearDown(controller.dispose);

      expect(controller.state.stepId, OnboardingStepId.review);
      expect(controller.state.draft.targets.dailySteps, 10000);
      expect(controller.state.draft.targets.waterMl, 2500);
      expect(controller.state.draft.targets.hasDailyStepsValue, isFalse);
      expect(
          controller.state.draft.targets.hasSleepTargetMinutesValue, isFalse);
      expect(controller.state.draft.targets.hasSleepTimeMinutesValue, isFalse);
      expect(controller.state.draft.targets.hasWakeTimeMinutesValue, isFalse);
      expect(controller.state.draft.targets.hasWaterMlValue, isFalse);

      final wellness = body_owner.InMemoryWellnessTargetsRepository();
      final nutritionTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final persist = PersistOnboardingOwnerDataUseCase(
        profileRepository: _MemoryUserProfileRepository(),
        bodyRepository: body_owner.InMemoryBodySetupRepository(),
        wellnessRepository: wellness,
        nutritionProfileRepository:
            nutrition_owner.InMemoryNutritionProfileRepository(),
        workoutProfileRepository:
            workout_owner.InMemoryWorkoutProfileRepository(),
        workoutTargetsRepository:
            workout_owner.InMemoryWorkoutTargetsRepository(),
        nutritionTargetsRepository: nutritionTargets,
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.resumeDraft,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await persist(draft: controller.state.draft, flowPlan: flowPlan);

      expect(
        await wellness.read(),
        const body_owner.WellnessTargetsData(),
      );

      // Compatibility UI defaults remain available to the recommendation
      // calculation without being promoted to canonical Wellness truth.
      final calculatedTargets = await nutritionTargets.read();
      expect(calculatedTargets, isNotNull);
      expect(calculatedTargets?.caloriesKcal, isNotNull);

      final autosaved = snapshotMapper.toJson(
        OnboardingDraftSnapshot(draft: controller.state.draft),
      );
      final reloaded = snapshotMapper.fromJson(autosaved).draft.targets;
      expect(reloaded.hasDailyStepsValue, isFalse);
      expect(reloaded.hasSleepTargetMinutesValue, isFalse);
      expect(reloaded.hasSleepTimeMinutesValue, isFalse);
      expect(reloaded.hasWakeTimeMinutesValue, isFalse);
      expect(reloaded.hasWaterMlValue, isFalse);
      expect(
        const WellnessTargetsMapper().map(reloaded),
        const body_owner.WellnessTargetsData(),
      );
    });

    test(
        'partial legacy Wellness provenance persists only values that actually existed',
        () async {
      const snapshotMapper = OnboardingDraftSnapshotDtoMapper();
      final sourceJson = snapshotMapper.toJson(
        OnboardingDraftSnapshot(draft: _draft()),
      );
      sourceJson['schema_version'] = 2;
      final targetsJson = sourceJson['targets'] as Map<String, dynamic>;
      targetsJson
        ..['daily_steps'] = 8750
        ..['sleep_time_minutes'] = 1410
        ..remove('sleep_target_minutes')
        ..remove('wake_time_minutes')
        ..remove('water_ml')
        ..remove('daily_steps_known')
        ..remove('sleep_target_minutes_known')
        ..remove('sleep_time_minutes_known')
        ..remove('wake_time_minutes_known')
        ..remove('water_ml_known');

      final restored = snapshotMapper.fromJson(sourceJson).draft;
      final wellness = body_owner.InMemoryWellnessTargetsRepository();
      final persist = PersistOnboardingOwnerDataUseCase(
        profileRepository: _MemoryUserProfileRepository(),
        bodyRepository: body_owner.InMemoryBodySetupRepository(),
        wellnessRepository: wellness,
        nutritionProfileRepository:
            nutrition_owner.InMemoryNutritionProfileRepository(),
        workoutProfileRepository:
            workout_owner.InMemoryWorkoutProfileRepository(),
        workoutTargetsRepository:
            workout_owner.InMemoryWorkoutTargetsRepository(),
        nutritionTargetsRepository:
            nutrition_owner.InMemoryNutritionTargetsRepository(),
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.resumeDraft,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await persist(draft: restored, flowPlan: flowPlan);

      expect(
        await wellness.read(),
        const body_owner.WellnessTargetsData(
          dailySteps: 8750,
          bedTimeMinutes: 1410,
        ),
      );
    });

    test(
        'Wellness owner failure blocks Nutrition, mode and completion publication',
        () async {
      final operations = <String>[];
      final nutritionProfile = _RecordingNutritionProfileRepository(operations);
      final workoutProfile = workout_owner.InMemoryWorkoutProfileRepository();
      final workoutTargets = workout_owner.InMemoryWorkoutTargetsRepository();
      final nutritionTargets = _RecordingNutritionTargetsRepository(operations);
      final preference = _RecordingAppModePreference(operations);
      final status = _RecordingOnboardingStatusRepository(operations);
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: preference,
        statusRepository: status,
        persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
          profileRepository: _RecordingProfileRepository(operations),
          bodyRepository: _RecordingBodyRepository(operations),
          wellnessRepository: _FailingWellnessRepository(operations),
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
      final draft = _draft();
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await expectLater(
        () => useCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (error) => error.owner,
            'owner',
            OwnerPersistenceTarget.wellness,
          ),
        ),
      );

      expect(nutritionProfile.upsertCalls, 0);
      expect(await workoutProfile.read(), isNull);
      expect(await workoutTargets.read(), isNull);
      expect(nutritionTargets.upsertCalls, 0);
      expect(preference.storedMode, isNull);
      expect(status.status, isNull);
      expect(
        operations,
        [
          'status.ensureInitialized',
          'profile.upsert',
          'body.save',
          'wellness.upsert',
        ],
      );
    });
  });
}

OnboardingDraft _draft({
  AppMode mode = AppMode.nutrition,
  GoalIntentSelection goalSelection = const GoalIntentSelection(
    primaryGoal: GoalIntent.maintainWeight,
  ),
  TargetsOnboardingDraft targets = const TargetsOnboardingDraft(
    currentStepId: TargetStepId.nutritionTarget,
  ),
}) {
  return OnboardingDraft(
    status: OnboardingStatus.inProgress,
    selectedMode: mode,
    goalSelection: goalSelection,
    currentStepId: OnboardingStepId.review,
    completedStepIds: const {
      OnboardingStepId.profileBasics,
      OnboardingStepId.bodyGoal,
      OnboardingStepId.wellnessGoals,
      OnboardingStepId.targets,
    },
    profile: ProfileOnboardingDraft(
      currentStepId: ProfileStepId.activity,
      name: 'Wellness Accepted',
      gender: ProfileGender.female,
      dateOfBirth: DateTime(1994, 5, 6),
      unitPreferences: UnitPreferences.metric,
      heightCm: 168,
      currentWeightKg: 64,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {ProfileHealthCondition.none},
    ),
    targets: targets,
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

class _FailingWellnessRepository
    implements body_owner.WellnessTargetsRepository {
  _FailingWellnessRepository(this.operations);

  final List<String> operations;

  @override
  Future<body_owner.WellnessTargetsData?> read() async => null;

  @override
  Future<void> upsert(body_owner.WellnessTargetsData targets) async {
    operations.add('wellness.upsert');
    throw StateError('canonical Wellness write failed');
  }
}

class _RecordingNutritionProfileRepository
    implements nutrition_owner.NutritionProfileRepository {
  _RecordingNutritionProfileRepository(this.operations);

  final List<String> operations;
  int upsertCalls = 0;

  @override
  Future<nutrition_owner.NutritionProfileData?> read() async => null;

  @override
  Future<void> upsert(nutrition_owner.NutritionProfileData profile) async {
    upsertCalls += 1;
    operations.add('nutritionProfile.upsert');
  }
}

class _RecordingNutritionTargetsRepository
    implements nutrition_owner.NutritionTargetsRepository {
  _RecordingNutritionTargetsRepository(this.operations);

  final List<String> operations;
  int upsertCalls = 0;

  @override
  Future<nutrition_owner.NutritionTargetsData?> read() async => null;

  @override
  Future<void> upsert(nutrition_owner.NutritionTargetsData targets) async {
    upsertCalls += 1;
    operations.add('nutritionTargets.upsert');
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

class _RecordingAppModePreference implements AppModePreference {
  _RecordingAppModePreference(this.operations);

  final List<String> operations;
  AppMode? storedMode;

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
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

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return OnboardingStatusSnapshot(
      status: status,
      hasStoredContractVersion: status != null,
    );
  }

  @override
  Future<void> ensureInitialized() async {
    operations.add('status.ensureInitialized');
  }

  @override
  Future<void> write(OnboardingStatus status) async {
    this.status = status;
    operations.add('status.write.${status.name}');
  }

  @override
  Future<void> clear() async {
    status = null;
  }
}

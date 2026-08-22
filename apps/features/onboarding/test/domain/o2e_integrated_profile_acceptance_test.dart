import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  group('O2E integrated canonical Profile acceptance', () {
    test(
        'canonical read beats stale legacy mirror, onboarding write round-trips, and resume keeps userProfile',
        () async {
      final operations = <String>[];
      final canonicalBefore = _canonicalProfile(name: 'Canonical Before');
      final canonical = _MemoryUserProfileRepository(
        initialData: canonicalBefore,
        operations: operations,
      );
      final legacy = _LegacyProfileRepository(
        initialData: _legacyProfile(name: 'Stale Legacy Mirror'),
      );
      final bridge = profile_owner.CanonicalUserProfileBridgeRepository(
        legacyRepository: legacy,
        canonicalRepository: canonical,
      );

      // Canonical common Profile reads never fall back to or merge stale
      // legacy `users` mirrors exposed by the broad compatibility API.
      expect(await bridge.read(), canonicalBefore);
      expect((await bridge.getProfileSetup())?.name, 'Stale Legacy Mirror');

      final body = body_owner.InMemoryBodySetupRepository();
      final wellness = body_owner.InMemoryWellnessTargetsRepository();
      final nutritionProfile =
          nutrition_owner.InMemoryNutritionProfileRepository();
      final workoutProfile = workout_owner.InMemoryWorkoutProfileRepository();
      final workoutTargets = workout_owner.InMemoryWorkoutTargetsRepository();
      final nutritionTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final persist = PersistOnboardingOwnerDataUseCase(
        profileRepository: bridge,
        bodyRepository: body,
        wellnessRepository: wellness,
        nutritionProfileRepository: nutritionProfile,
        workoutProfileRepository: workoutProfile,
        workoutTargetsRepository: workoutTargets,
        nutritionTargetsRepository: nutritionTargets,
      );
      final draft = _draft();
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await persist(draft: draft, flowPlan: flowPlan);

      final expected = _canonicalProfile(name: 'Accepted User');
      expect(canonical.data, expected);
      expect(await bridge.read(), expected);
      expect(legacy.saveCalls, 0);
      expect((await bridge.getProfileSetup())?.name, 'Stale Legacy Mirror');

      // Current Weight remains Body-owned and never enters UserProfileData.
      expect(body.data?.currentWeightKg, 64);
      expect(body.data?.activeGoal?.targetWeightKg, isNull);
      expect(await workoutProfile.read(), isNull);
      expect(await workoutTargets.read(), isNull);
      expect(await nutritionTargets.read(), isNotNull);

      // Persisted onboarding resume identity remains the stable top-level
      // `profileBasics` step. The active plan resolves it to `userProfile`.
      const snapshotMapper = OnboardingDraftSnapshotDtoMapper();
      final restored = snapshotMapper.fromJson(
        snapshotMapper.toJson(OnboardingDraftSnapshot(draft: draft)),
      );
      final resumed = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: restored.draft,
      );
      addTearDown(resumed.dispose);

      expect(resumed.state.stepId, OnboardingStepId.profileBasics);
      expect(resumed.state.currentSection, OnboardingSectionId.userProfile);
      expect(resumed.state.draft.profile.name, 'Accepted User');
      expect(
        resumed.state.draft.profile.currentStepId,
        ProfileStepId.activity,
      );
      expect(resumed.state.draft.profile.currentWeightKg, 64);
      expect(
        operations.where((value) => value == 'canonical.profile.upsert'),
        hasLength(1),
      );
    });

    test('completion publishes canonical Profile before mode and completion',
        () async {
      final operations = <String>[];
      final canonical = _MemoryUserProfileRepository(operations: operations);
      final legacy = _LegacyProfileRepository(
        initialData: _legacyProfile(name: 'Stale Legacy Mirror'),
      );
      final bridge = profile_owner.CanonicalUserProfileBridgeRepository(
        legacyRepository: legacy,
        canonicalRepository: canonical,
      );
      final body = body_owner.InMemoryBodySetupRepository();
      final wellness = body_owner.InMemoryWellnessTargetsRepository();
      final nutritionProfile =
          nutrition_owner.InMemoryNutritionProfileRepository();
      final workoutProfile = workout_owner.InMemoryWorkoutProfileRepository();
      final workoutTargets = workout_owner.InMemoryWorkoutTargetsRepository();
      final nutritionTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final preference = _RecordingAppModePreference(operations);
      final status = _RecordingOnboardingStatusRepository(operations);
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: preference,
        statusRepository: status,
        persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
          profileRepository: bridge,
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
      final draft = _draft();
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await useCase(draft: draft, flowPlan: flowPlan);

      expect(canonical.data, _canonicalProfile(name: 'Accepted User'));
      expect(legacy.saveCalls, 0);
      expect(body.data?.currentWeightKg, 64);
      expect(await workoutProfile.read(), isNull);
      expect(await workoutTargets.read(), isNull);
      expect(await nutritionTargets.read(), isNotNull);
      expect(preference.storedMode, AppMode.nutrition);
      expect(status.status, OnboardingStatus.completed);
      expect(
        operations,
        [
          'status.ensureInitialized',
          'canonical.profile.upsert',
          'mode.write.nutrition',
          'status.write.completed',
        ],
      );
    });

    test('canonical Profile failure blocks Body and completion publication',
        () async {
      final operations = <String>[];
      final canonical = _MemoryUserProfileRepository(
        operations: operations,
        writeError: StateError('canonical profile write failed'),
      );
      final legacy = _LegacyProfileRepository(
        initialData: _legacyProfile(name: 'Stale Legacy Mirror'),
      );
      final bridge = profile_owner.CanonicalUserProfileBridgeRepository(
        legacyRepository: legacy,
        canonicalRepository: canonical,
      );
      final body = body_owner.InMemoryBodySetupRepository();
      final preference = _RecordingAppModePreference(operations);
      final status = _RecordingOnboardingStatusRepository(operations);
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: preference,
        statusRepository: status,
        persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
          profileRepository: bridge,
          bodyRepository: body,
          nutritionProfileRepository:
              nutrition_owner.InMemoryNutritionProfileRepository(),
          workoutProfileRepository:
              workout_owner.InMemoryWorkoutProfileRepository(),
          workoutTargetsRepository:
              workout_owner.InMemoryWorkoutTargetsRepository(),
          nutritionTargetsRepository:
              nutrition_owner.InMemoryNutritionTargetsRepository(),
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
            OwnerPersistenceTarget.profile,
          ),
        ),
      );

      expect(body.data, isNull);
      expect(preference.storedMode, isNull);
      expect(status.status, isNull);
      expect(legacy.saveCalls, 0);
      expect(
        operations,
        [
          'status.ensureInitialized',
          'canonical.profile.upsert',
        ],
      );
    });
  });
}

profile_owner.UserProfileData _canonicalProfile({required String name}) {
  return profile_owner.UserProfileData(
    name: name,
    gender: profile_owner.ProfileGender.female,
    dateOfBirth: DateTime(1994, 5, 6),
    unitPreferences: MeasurementUnitPreferences.imperial,
    heightCm: 168,
    activityLevel: profile_owner.ProfileActivityLevel.active,
    healthConditions: const {
      profile_owner.ProfileHealthCondition.hypertension,
      profile_owner.ProfileHealthCondition.other,
    },
    otherHealthCondition: 'Migraine',
  );
}

profile_owner.ProfileSetupData _legacyProfile({required String name}) {
  return profile_owner.ProfileSetupData(
    name: name,
    gender: profile_owner.ProfileGender.male,
    goals: const {profile_owner.ProfileGoal.buildMuscle},
    dateOfBirth: DateTime(1980, 1, 1),
    heightCm: 190,
    currentWeightKg: 110,
    targetWeightKg: 95,
    unitPreferences: MeasurementUnitPreferences.metric,
    activityLevel: profile_owner.ProfileActivityLevel.sedentary,
    healthConditions: const {profile_owner.ProfileHealthCondition.none},
  );
}

OnboardingDraft _draft() {
  return OnboardingDraft(
    selectedMode: AppMode.nutrition,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.maintainWeight,
    ),
    currentStepId: OnboardingStepId.profileBasics,
    profile: ProfileOnboardingDraft(
      currentStepId: ProfileStepId.activity,
      name: 'Accepted User',
      gender: ProfileGender.female,
      dateOfBirth: DateTime(1994, 5, 6),
      unitPreferences: MeasurementUnitPreferences.imperial,
      heightCm: 168,
      currentWeightKg: 64,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {
        ProfileHealthCondition.hypertension,
        ProfileHealthCondition.other,
      },
      otherHealthCondition: 'Migraine',
    ),
    targets: const TargetsOnboardingDraft(
      dailySteps: 9000,
      sleepTargetMinutes: 480,
      sleepTimeMinutes: 1320,
      wakeTimeMinutes: 360,
      waterMl: 2200,
      goalPaceKgPerWeek: 0,
    ),
  );
}

class _MemoryUserProfileRepository
    implements profile_owner.UserProfileRepository {
  _MemoryUserProfileRepository({
    this.initialData,
    this.operations,
    this.writeError,
  }) : data = initialData;

  final profile_owner.UserProfileData? initialData;
  final List<String>? operations;
  final Object? writeError;
  profile_owner.UserProfileData? data;

  @override
  Future<profile_owner.UserProfileData?> read() async => data;

  @override
  Future<void> upsert(profile_owner.UserProfileData profile) async {
    operations?.add('canonical.profile.upsert');
    if (writeError case final error?) throw error;
    data = profile;
  }
}

class _LegacyProfileRepository
    implements profile_owner.ProfileSetupRepository {
  _LegacyProfileRepository({required this.initialData}) : data = initialData;

  final profile_owner.ProfileSetupData initialData;
  profile_owner.ProfileSetupData? data;
  int saveCalls = 0;

  @override
  Future<void> saveProfileSetup(profile_owner.ProfileSetupData data) async {
    saveCalls += 1;
    this.data = data;
  }

  @override
  Future<profile_owner.ProfileSetupData?> getProfileSetup() async => data;

  @override
  Stream<profile_owner.ProfileSetupData?> watchProfileSetup() =>
      Stream<profile_owner.ProfileSetupData?>.value(data);

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async =>
      'memory://$fileName';

  @override
  Future<void> deleteAvatarImage() async {}

  @override
  Future<void> updateAvatarFrame(String frame) async {}
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

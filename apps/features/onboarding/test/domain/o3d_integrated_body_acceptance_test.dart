import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  group('O3D integrated canonical Body acceptance', () {
    test(
        'directional Body mapping round-trips and retries preserve lifecycle semantics',
        () async {
      var now = DateTime.utc(2026, 8, 22, 8);
      final repository = body_owner.InMemoryBodySetupRepository(now: () => now);
      const mapper = BodySetupMapper();

      final first = mapper.map(
        _bodyDraft(
          goal: GoalIntent.loseWeight,
          currentWeightKg: 80,
          targetWeightKg: 74,
          direction: GoalWeightDirection.loss,
          paceKgPerWeek: 0.6,
        ),
      );

      expect(first.currentWeightKg, 80);
      expect(first.activeGoal?.goalType, body_owner.BodyGoalType.loseWeight);
      expect(first.activeGoal?.targetWeightKg, 74);
      expect(first.activeGoal?.weeklyWeightChangeKg, 0.6);
      expect(first.activeGoal?.intentRank, 1);

      await repository.saveBodySetup(first);
      final firstState = await repository.getBodyState();

      expect(firstState.latestWeight?.weightKg, 80);
      expect(
        firstState.latestWeight?.source,
        body_owner.BodyWeightSources.onboardingSetup,
      );
      expect(firstState.activeGoal?.goalType, body_owner.BodyGoalType.loseWeight);
      expect(firstState.activeGoal?.startingWeightKg, 80);
      expect(firstState.activeGoal?.targetWeightKg, 74);
      expect(firstState.activeGoal?.weeklyWeightChangeKg, 0.6);
      expect(firstState.activeGoal?.intentRank, 1);
      expect(firstState.activeGoal?.startedAt, now);
      expect(repository.weightEntries, hasLength(1));

      final firstStartedAt = firstState.activeGoal?.startedAt;
      now = DateTime.utc(2026, 8, 22, 9);

      await repository.saveBodySetup(
        mapper.map(
          _bodyDraft(
            goal: GoalIntent.loseWeight,
            currentWeightKg: 79,
            targetWeightKg: 73,
            direction: GoalWeightDirection.loss,
            paceKgPerWeek: 0.5,
          ),
        ),
      );

      final retryState = await repository.getBodyState();
      expect(repository.weightEntries, hasLength(1));
      expect(retryState.latestWeight?.weightKg, 79);
      expect(retryState.activeGoal?.startingWeightKg, 80);
      expect(retryState.activeGoal?.startedAt, firstStartedAt);
      expect(retryState.activeGoal?.targetWeightKg, 73);
      expect(retryState.activeGoal?.weeklyWeightChangeKg, 0.5);

      now = DateTime.utc(2026, 8, 22, 10);
      await repository.saveBodySetup(
        mapper.map(
          _bodyDraft(
            goal: GoalIntent.gainWeight,
            currentWeightKg: 79,
            targetWeightKg: 84,
            direction: GoalWeightDirection.gain,
            paceKgPerWeek: 0.3,
          ),
        ),
      );

      final changedGoalState = await repository.getBodyState();
      expect(repository.weightEntries, hasLength(1));
      expect(changedGoalState.latestWeight?.weightKg, 79);
      expect(
        changedGoalState.activeGoal?.goalType,
        body_owner.BodyGoalType.gainWeight,
      );
      expect(changedGoalState.activeGoal?.startingWeightKg, 79);
      expect(changedGoalState.activeGoal?.targetWeightKg, 84);
      expect(changedGoalState.activeGoal?.weeklyWeightChangeKg, 0.3);
      expect(changedGoalState.activeGoal?.startedAt, now);
    });

    test(
        'non-directional and training-only intents never consume dormant Body follow-ups',
        () async {
      const mapper = BodySetupMapper();
      final repository = body_owner.InMemoryBodySetupRepository(
        now: () => DateTime.utc(2026, 8, 22, 8),
      );

      final maintain = mapper.map(
        _bodyDraft(
          goal: GoalIntent.maintainWeight,
          currentWeightKg: 80,
          targetWeightKg: 72,
          direction: GoalWeightDirection.loss,
          paceKgPerWeek: 0.8,
        ),
      );

      expect(
        maintain.activeGoal?.goalType,
        body_owner.BodyGoalType.maintainWeight,
      );
      expect(maintain.activeGoal?.targetWeightKg, isNull);
      expect(maintain.activeGoal?.weeklyWeightChangeKg, isNull);

      await repository.saveBodySetup(maintain);
      final maintainState = await repository.getBodyState();
      expect(maintainState.latestWeight?.weightKg, 80);
      expect(
        maintainState.activeGoal?.goalType,
        body_owner.BodyGoalType.maintainWeight,
      );
      expect(maintainState.activeGoal?.targetWeightKg, isNull);
      expect(maintainState.activeGoal?.weeklyWeightChangeKg, isNull);

      final trainingOnly = mapper.map(
        OnboardingDraft(
          selectedMode: AppMode.workout,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.getStronger,
          ),
          profile: ProfileOnboardingDraft(
            currentWeightKg: 82,
            targetWeightKg: 60,
            targetWeightDirection: GoalWeightDirection.loss,
          ),
          targets: const TargetsOnboardingDraft(
            goalPaceKgPerWeek: 1.2,
          ),
        ),
      );

      expect(trainingOnly.currentWeightKg, 82);
      expect(trainingOnly.activeGoal, isNull);

      await repository.saveBodySetup(trainingOnly);
      final trainingState = await repository.getBodyState();
      expect(trainingState.latestWeight?.weightKg, 82);
      expect(trainingState.activeGoal, isNull);
    });

    test(
        'Body owner failure blocks later canonical owners, mode, and completion publication',
        () async {
      final operations = <String>[];
      final profileRepository = _RecordingProfileRepository(operations);
      final bodyRepository = _FailingBodyRepository(operations);
      final nutritionProfileRepository =
          nutrition_owner.InMemoryNutritionProfileRepository();
      final nutritionTargetsRepository =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final preference = _RecordingAppModePreference(operations);
      final status = _RecordingOnboardingStatusRepository(operations);
      final useCase = CompleteOnboardingUseCase(
        confirmedModePreference: preference,
        statusRepository: status,
        persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
          profileRepository: profileRepository,
          bodyRepository: bodyRepository,
          nutritionProfileRepository: nutritionProfileRepository,
          workoutProfileRepository:
              workout_owner.InMemoryWorkoutProfileRepository(),
          workoutTargetsRepository:
              workout_owner.InMemoryWorkoutTargetsRepository(),
          nutritionTargetsRepository: nutritionTargetsRepository,
        ),
        validator: const OnboardingCompletionValidator(
          hasDurableOwnerPersistence: true,
          backendUserReady: true,
        ),
      );
      final draft = _completionDraft();
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
            OwnerPersistenceTarget.body,
          ),
        ),
      );

      expect(profileRepository.data, isNotNull);
      expect(bodyRepository.saveCalls, 1);
      expect(await nutritionProfileRepository.read(), isNull);
      expect(await nutritionTargetsRepository.read(), isNull);
      expect(preference.storedMode, isNull);
      expect(status.status, isNull);
      expect(
        operations,
        [
          'status.ensureInitialized',
          'profile.upsert',
          'body.save',
        ],
      );
    });

    test('serialized Goal Pace resume stays Body-owned and Targets stays pace-free',
        () {
      final source = _completionDraft().copyWith(
        currentStepId: OnboardingStepId.bodyGoal,
        profile: _completionDraft().profile.copyWith(
              currentStepId: ProfileStepId.goalPace,
            ),
      );
      const snapshotMapper = OnboardingDraftSnapshotDtoMapper();
      final restored = snapshotMapper.fromJson(
        snapshotMapper.toJson(OnboardingDraftSnapshot(draft: source)),
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: restored.draft,
      );
      addTearDown(controller.dispose);

      expect(controller.state.stepId, OnboardingStepId.bodyGoal);
      expect(controller.state.currentSection, OnboardingSectionId.bodyGoal);
      expect(
        controller.state.draft.profile.currentStepId,
        ProfileStepId.goalPace,
      );
      expect(controller.state.draft.targets.goalPaceKgPerWeek, 0.6);
      expect(
        controller.state.bodyGoalFlowPlan.contains(ProfileStepId.goalPace),
        isTrue,
      );
      expect(
        controller.state.targetsFlowPlan.contains(TargetStepId.goalPace),
        isFalse,
      );
    });
  });
}

OnboardingDraft _bodyDraft({
  required GoalIntent goal,
  required double currentWeightKg,
  required double targetWeightKg,
  required GoalWeightDirection direction,
  required double paceKgPerWeek,
}) {
  return OnboardingDraft(
    selectedMode: AppMode.nutrition,
    goalSelection: GoalIntentSelection(primaryGoal: goal),
    profile: ProfileOnboardingDraft(
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
      targetWeightDirection: direction,
    ),
    targets: TargetsOnboardingDraft(
      goalPaceKgPerWeek: paceKgPerWeek,
    ),
  );
}

OnboardingDraft _completionDraft() {
  return OnboardingDraft(
    status: OnboardingStatus.inProgress,
    selectedMode: AppMode.nutrition,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
    ),
    currentStepId: OnboardingStepId.review,
    completedStepIds: const {
      OnboardingStepId.profileBasics,
      OnboardingStepId.bodyGoal,
      OnboardingStepId.targets,
    },
    profile: ProfileOnboardingDraft(
      currentStepId: ProfileStepId.goalPace,
      name: 'Body Accepted',
      gender: ProfileGender.female,
      dateOfBirth: DateTime(1994, 5, 6),
      unitPreferences: MeasurementUnitPreferences.metric,
      heightCm: 168,
      currentWeightKg: 80,
      targetWeightKg: 74,
      targetWeightDirection: GoalWeightDirection.loss,
      activityLevel: ProfileActivityLevel.active,
      healthConditions: const {ProfileHealthCondition.none},
    ),
    targets: const TargetsOnboardingDraft(
      currentStepId: TargetStepId.nutritionTarget,
      dailySteps: 9000,
      sleepTargetMinutes: 480,
      sleepTimeMinutes: 1320,
      wakeTimeMinutes: 360,
      waterMl: 2200,
      goalPaceKgPerWeek: 0.6,
    ),
  );
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

class _FailingBodyRepository implements body_owner.BodySetupRepository {
  _FailingBodyRepository(this.operations);

  final List<String> operations;
  int saveCalls = 0;

  @override
  Future<void> saveBodySetup(body_owner.BodySetupData data) async {
    saveCalls += 1;
    operations.add('body.save');
    throw StateError('canonical Body write failed');
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

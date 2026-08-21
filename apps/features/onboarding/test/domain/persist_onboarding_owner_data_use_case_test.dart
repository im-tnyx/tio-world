import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/src/domain/domain.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  late profile_owner.InMemoryProfileSetupRepository profileRepo;
  late body_owner.InMemoryBodySetupRepository bodyRepo;
  late workout_owner.InMemoryWorkoutPreferencesRepository workoutRepo;
  late nutrition_owner.InMemoryTargetsSetupRepository targetsRepo;
  late PersistOnboardingOwnerDataUseCase useCase;

  setUp(() {
    profileRepo = profile_owner.InMemoryProfileSetupRepository();
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
    test('workout mode persists Profile, Body, Workout, and Targets', () async {
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

      expect(await profileRepo.getProfileSetup(), isNotNull);
      expect(bodyRepo.data, isNotNull);
      expect(bodyRepo.data?.currentWeightKg, 60);
      expect(await workoutRepo.getWorkoutPreferences(), isNotNull);
      expect(await targetsRepo.getTargetsSetup(), isNotNull);
    });

    test('nutrition mode persists Profile, Body and Targets, but NOT Workout',
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

      expect(await profileRepo.getProfileSetup(), isNotNull);
      expect(bodyRepo.data, isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      expect(await targetsRepo.getTargetsSetup(), isNotNull);
    });

    test('hybrid setupNow persists Profile, Body, Workout, and Targets',
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

      expect(await profileRepo.getProfileSetup(), isNotNull);
      expect(bodyRepo.data, isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNotNull);
      expect(await targetsRepo.getTargetsSetup(), isNotNull);
    });

    test('hybrid later persists Profile, Body and Targets, but NOT Workout',
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

      expect(await profileRepo.getProfileSetup(), isNotNull);
      expect(bodyRepo.data, isNotNull);
      expect(await workoutRepo.getWorkoutPreferences(), isNull);
      expect(await targetsRepo.getTargetsSetup(), isNotNull);
    });

    test('active weight goal persists matching Target Weight and Goal Pace',
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

      expect(bodyRepo.data?.activeGoal?.goalType,
          body_owner.BodyGoalType.loseWeight);
      expect(bodyRepo.data?.activeGoal?.targetWeightKg, 58);
      expect(bodyRepo.data?.activeGoal?.weeklyWeightChangeKg, 0.5);
      expect(bodyRepo.data?.activeGoal?.intentRank, 1);

      // Compatibility owners are still present during the staged cutover.
      expect((await profileRepo.getProfileSetup())?.targetWeightKg, 58);
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

      expect(bodyRepo.data?.activeGoal?.goalType,
          body_owner.BodyGoalType.maintainWeight);
      expect(bodyRepo.data?.activeGoal?.targetWeightKg, isNull);
      expect(bodyRepo.data?.activeGoal?.weeklyWeightChangeKg, isNull);
      expect(bodyRepo.data?.activeGoal?.intentRank, 1);

      expect((await profileRepo.getProfileSetup())?.targetWeightKg, isNull);
      expect((await targetsRepo.getTargetsSetup())?.targetWeightKg, isNull);
      expect((await targetsRepo.getTargetsSetup())?.goalPaceKgPerWeek, 0.0);
    });

    test('re-throws OwnerPersistenceException when Profile repository fails',
        () async {
      final failingProfileRepo = _FailingProfileSetupRepository();
      final failingUseCase = PersistOnboardingOwnerDataUseCase(
        profileRepository: failingProfileRepo,
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

      expect(
        () => failingUseCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (e) => e.owner,
            'owner',
            OwnerPersistenceTarget.profile,
          ),
        ),
      );
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

      expect(
        () => failingUseCase(draft: draft, flowPlan: flowPlan),
        throwsA(
          isA<OwnerPersistenceException>().having(
            (e) => e.owner,
            'owner',
            OwnerPersistenceTarget.body,
          ),
        ),
      );
    });
  });
}

class _FailingProfileSetupRepository implements profile_owner.ProfileSetupRepository {
  @override
  Stream<profile_owner.ProfileSetupData?> watchProfileSetup() async* {
    yield null;
  }

  @override
  Future<void> saveProfileSetup(profile_owner.ProfileSetupData data) async {
    throw StateError('Profile database write failed');
  }

  @override
  Future<profile_owner.ProfileSetupData?> getProfileSetup() async => null;

  @override
  Future<String> uploadAvatarImage({
    required String fileName,
    required List<int> bytes,
  }) async =>
      '';

  @override
  Future<void> deleteAvatarImage() async {}

  @override
  Future<void> updateAvatarFrame(String frame) async {}
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

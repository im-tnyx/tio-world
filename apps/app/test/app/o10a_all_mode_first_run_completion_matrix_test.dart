import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  group('O10A all-mode first-run completion matrix', () {
    for (final variant in _variants) {
      test(variant.name, () async {
        final profileRepo = _FakeUserProfileRepository();
        final bodyRepo = body_owner.InMemoryBodySetupRepository();
        final wellnessRepo = body_owner.InMemoryWellnessTargetsRepository();
        final nutritionProfileRepo =
            nutrition_owner.InMemoryNutritionProfileRepository();
        final nutritionTargetsRepo =
            nutrition_owner.InMemoryNutritionTargetsRepository();
        final workoutProfileRepo =
            workout_owner.InMemoryWorkoutProfileRepository();
        final workoutTargetsRepo =
            workout_owner.InMemoryWorkoutTargetsRepository();

        final persistOwners = PersistOnboardingOwnerDataUseCase(
          profileRepository: profileRepo,
          bodyRepository: bodyRepo,
          wellnessRepository: wellnessRepo,
          nutritionProfileRepository: nutritionProfileRepo,
          nutritionTargetsRepository: nutritionTargetsRepo,
          workoutProfileRepository: workoutProfileRepo,
          workoutTargetsRepository: workoutTargetsRepo,
        );

        final draft = OnboardingDraft(
          status: OnboardingStatus.inProgress,
          selectedMode: variant.mode,
          workoutIntroChoice: variant.workoutIntroChoice,
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
          workout: _validWorkout(),
          targets: _validTargets(),
        );
        final flowPlan = const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: variant.mode,
          workoutIntroChoice: variant.workoutIntroChoice,
        );

        final draftRepository = InMemoryOnboardingDraftRepository(
          initialSnapshot: OnboardingDraftSnapshot(draft: draft),
        );
        final modePreference = _FakeAppModePreference();
        final statusRepository = _FakeOnboardingStatusRepository();
        final remoteState = _FakeCompletionAndPreferencesRepository();

        final complete = CompleteOnboardingUseCase(
          confirmedModePreference: modePreference,
          appPreferencesRepository: remoteState,
          statusRepository: statusRepository,
          persistOwnerDataUseCase: persistOwners,
          completionRepository: remoteState,
          draftRepository: draftRepository,
          validator: const OnboardingCompletionValidator(
            hasDurableOwnerPersistence: true,
            backendUserReady: true,
          ),
        );

        await complete(draft: draft, flowPlan: flowPlan);

        expect(profileRepo.data?.name, 'Tio User');
        expect(bodyRepo.data?.currentWeightKg, 60);
        if (variant.publishesWellness) {
          expect(wellnessRepo.data?.dailySteps, 10000);
          expect(wellnessRepo.data?.waterMl, 2500);
        } else {
          expect(wellnessRepo.data, isNull);
        }

        expect(
          await nutritionProfileRepo.read(),
          variant.publishesNutritionProfile ? isNotNull : isNull,
        );

        final nutritionTargets = await nutritionTargetsRepo.read();
        if (variant.publishesNutritionTargets) {
          expect(nutritionTargets, isNotNull);
          expect(
            nutritionTargets?.customizationState,
            nutrition_owner.NutritionTargetCustomizationState.recommended,
          );
          expect(nutritionTargets?.customizedFields, isEmpty);
          expect(nutritionTargets?.recommendationMetadata['source'], 'onboarding');
          expect(nutritionTargets?.caloriesKcal, greaterThan(0));
        } else {
          expect(nutritionTargets, isNull);
        }

        final workoutProfile = await workoutProfileRepo.read();
        final workoutTargets = await workoutTargetsRepo.read();
        if (variant.publishesWorkout) {
          expect(workoutProfile, isNotNull);
          expect(workoutTargets, isNotNull);
          expect(
            workoutTargets?.primaryWorkoutGoal,
            workout_owner.WorkoutTargetGoal.stayFit,
          );
          expect(
            workoutTargets?.supportingWorkoutGoal,
            workout_owner.WorkoutTargetGoal.improveEndurance,
          );
          expect(workoutTargets?.primaryGoalRank, 1);
          expect(workoutTargets?.supportingGoalRank, 2);
          expect(workoutTargets?.trainingDays, hasLength(2));
          expect(workoutTargets?.preferredDurationMins, 60);
          expect(
            workoutTargets?.splitProgram,
            workout_owner.WorkoutSplit.upperLower,
          );
          expect(workoutTargets?.specialEvent, '10K race');
        } else {
          expect(workoutProfile, isNull);
          expect(workoutTargets, isNull);
        }

        if (variant.workoutIntroChoice == WorkoutIntroChoice.later) {
          expect(draft.workout.gymAccess, WorkoutGymAccess.gym);
          expect(draft.workout.specialEvent, '10K race');
        }

        expect(modePreference.storedMode, variant.mode);
        expect(remoteState.preferencesState.isPresent, isTrue);
        expect(remoteState.preferencesState.appMode, variant.mode);
        expect(
          remoteState.preferencesState.activeTabs,
          variant.mode.guidedDestinations,
        );
        expect(
          remoteState.completionState,
          RemoteOnboardingCompletionState.completed,
        );
        expect(statusRepository.status, OnboardingStatus.completed);
        expect(await draftRepository.loadDraft(), isNull);

        expect(
          appModeRedirect(
            path: AppRoutes.congratulations.path,
            selectedMode: modePreference.storedMode,
            activeDestinations: remoteState.preferencesState.activeTabs,
            onboardingStatus: statusRepository.status!,
          ),
          isNull,
        );
        expect(
          appModeRedirect(
            path: AppRoutes.onboarding.path,
            selectedMode: modePreference.storedMode,
            activeDestinations: remoteState.preferencesState.activeTabs,
            onboardingStatus: statusRepository.status!,
          ),
          FeatureRoutes.home.path,
        );
      });
    }
  });
}

class _Variant {
  const _Variant({
    required this.name,
    required this.mode,
    required this.publishesWellness,
    required this.publishesNutritionProfile,
    required this.publishesNutritionTargets,
    required this.publishesWorkout,
    this.workoutIntroChoice,
  });

  final String name;
  final AppMode mode;
  final WorkoutIntroChoice? workoutIntroChoice;
  final bool publishesWellness;
  final bool publishesNutritionProfile;
  final bool publishesNutritionTargets;
  final bool publishesWorkout;
}

const _variants = <_Variant>[
  _Variant(
    name: 'Workout completes with Body and Workout owners only',
    mode: AppMode.workout,
    publishesWellness: false,
    publishesNutritionProfile: false,
    publishesNutritionTargets: false,
    publishesWorkout: true,
  ),
  _Variant(
    name: 'Nutrition completes with Wellness and Nutrition owners only',
    mode: AppMode.nutrition,
    publishesWellness: true,
    publishesNutritionProfile: true,
    publishesNutritionTargets: true,
    publishesWorkout: false,
  ),
  _Variant(
    name: 'Hybrid setupNow completes with Wellness, Nutrition and Workout owners',
    mode: AppMode.hybrid,
    workoutIntroChoice: WorkoutIntroChoice.setupNow,
    publishesWellness: true,
    publishesNutritionProfile: true,
    publishesNutritionTargets: true,
    publishesWorkout: true,
  ),
  _Variant(
    name: 'Hybrid later completes with Wellness and Nutrition owners and dormant Workout',
    mode: AppMode.hybrid,
    workoutIntroChoice: WorkoutIntroChoice.later,
    publishesWellness: true,
    publishesNutritionProfile: true,
    publishesNutritionTargets: true,
    publishesWorkout: false,
  ),
];

class _FakeUserProfileRepository implements profile_owner.UserProfileRepository {
  profile_owner.UserProfileData? data;

  @override
  Future<profile_owner.UserProfileData?> read() async => data;

  @override
  Future<void> upsert(profile_owner.UserProfileData profile) async {
    data = profile;
  }
}

class _FakeCompletionAndPreferencesRepository
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

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  group('O5E integrated canonical Nutrition acceptance', () {
    test('all active mode branches persist only eligible canonical owners',
        () async {
      const cases = <_ModeCase>[
        _ModeCase(
          mode: AppMode.workout,
          expectNutritionProfile: false,
          expectWorkout: true,
        ),
        _ModeCase(
          mode: AppMode.nutrition,
          expectNutritionProfile: true,
          expectWorkout: false,
        ),
        _ModeCase(
          mode: AppMode.hybrid,
          workoutIntroChoice: WorkoutIntroChoice.setupNow,
          expectNutritionProfile: true,
          expectWorkout: true,
        ),
        _ModeCase(
          mode: AppMode.hybrid,
          workoutIntroChoice: WorkoutIntroChoice.later,
          expectNutritionProfile: true,
          expectWorkout: false,
        ),
      ];

      for (final testCase in cases) {
        final nutritionProfile =
            nutrition_owner.InMemoryNutritionProfileRepository();
        final nutritionTargets =
            nutrition_owner.InMemoryNutritionTargetsRepository();
        final workoutProfile = workout_owner.InMemoryWorkoutProfileRepository();
        final workoutTargets = workout_owner.InMemoryWorkoutTargetsRepository();
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
          mode: testCase.mode,
          workoutIntroChoice: testCase.workoutIntroChoice,
        );
        final flowPlan = const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: testCase.mode,
          workoutIntroChoice: testCase.workoutIntroChoice,
        );

        await persist(draft: draft, flowPlan: flowPlan);

        final storedProfile = await nutritionProfile.read();
        final storedWorkoutProfile = await workoutProfile.read();
        final storedWorkoutTargets = await workoutTargets.read();
        final storedTargets = await nutritionTargets.read();

        if (testCase.expectNutritionProfile) {
          expect(storedProfile, isNotNull, reason: testCase.label);
          expect(storedTargets, isNotNull, reason: testCase.label);
        } else {
          expect(storedProfile, isNull, reason: testCase.label);
          expect(storedTargets, isNull, reason: testCase.label);
        }
        if (testCase.expectWorkout) {
          expect(storedWorkoutProfile, isNotNull, reason: testCase.label);
          expect(storedWorkoutTargets, isNotNull, reason: testCase.label);
        } else {
          expect(storedWorkoutProfile, isNull, reason: testCase.label);
          expect(storedWorkoutTargets, isNull, reason: testCase.label);
        }
      }
    });

    test('Nutrition Profile write-read preserves allergy provenance', () async {
      const cases = <_AllergyCase>[
        _AllergyCase(
          label: 'unanswered',
          draft: NutritionOnboardingDraft(
            dietType: NutritionDietType.vegan,
          ),
          expectedAllergies: null,
        ),
        _AllergyCase(
          label: 'explicit none',
          draft: NutritionOnboardingDraft(
            dietType: NutritionDietType.vegetarian,
            allergyRestrictions: {NutritionAllergyRestriction.none},
          ),
          expectedAllergies: <String>{},
        ),
        _AllergyCase(
          label: 'selected restrictions',
          draft: NutritionOnboardingDraft(
            dietType: NutritionDietType.nonVegetarian,
            allergyRestrictions: {
              NutritionAllergyRestriction.gluten,
              NutritionAllergyRestriction.nuts,
            },
          ),
          expectedAllergies: {'gluten', 'nuts'},
        ),
      ];

      for (final testCase in cases) {
        final repository = nutrition_owner.InMemoryNutritionProfileRepository();
        final persist = _persistUseCase(nutritionProfileRepository: repository);
        final draft = _validDraft(
          mode: AppMode.nutrition,
          nutrition: testCase.draft,
        );
        final flowPlan = const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: AppMode.nutrition,
          workoutIntroChoice: null,
        );

        await persist(draft: draft, flowPlan: flowPlan);

        final stored = await repository.read();
        expect(stored, isNotNull, reason: testCase.label);
        expect(stored?.preferredDiet, testCase.draft.dietType?.storageValue);
        final expectedAllergies = testCase.expectedAllergies;
        if (expectedAllergies == null) {
          expect(stored?.allergies, isNull, reason: testCase.label);
        } else {
          expect(stored?.allergies, equals(expectedAllergies),
              reason: testCase.label);
        }
        expect(stored?.dislikedFoods, isNull, reason: testCase.label);
        expect(stored?.medicalConditions, isNull, reason: testCase.label);
      }
    });

    test('Nutrition Targets write-read preserves recommendation output',
        () async {
      final repository = nutrition_owner.InMemoryNutritionTargetsRepository();
      final persist = _persistUseCase(nutritionTargetsRepository: repository);
      final draft = _validDraft(mode: AppMode.nutrition);
      final expected = const NutritionTargetsMapper().map(draft);
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await persist(draft: draft, flowPlan: flowPlan);

      final stored = await repository.read();
      expect(stored?.caloriesKcal, expected.caloriesKcal);
      expect(stored?.proteinGrams, expected.proteinGrams);
      expect(stored?.carbohydrateGrams, expected.carbohydrateGrams);
      expect(stored?.fatGrams, expected.fatGrams);
      expect(stored?.fiberGrams, expected.fiberGrams);
      expect(
        stored?.customizationState,
        nutrition_owner.NutritionTargetCustomizationState.recommended,
      );
      expect(stored?.customizedFields, isEmpty);
      expect(
        stored?.recommendationMetadata,
        equals(expected.recommendationMetadata),
      );
    });

    test('supported customization states round-trip without normalization',
        () async {
      final repository = nutrition_owner.InMemoryNutritionTargetsRepository();

      for (final state in <nutrition_owner.NutritionTargetCustomizationState>[
        nutrition_owner.NutritionTargetCustomizationState.recommended,
        nutrition_owner.NutritionTargetCustomizationState.custom,
        nutrition_owner.NutritionTargetCustomizationState.mixed,
      ]) {
        final customizedFields = state ==
                nutrition_owner.NutritionTargetCustomizationState.recommended
            ? <String>{}
            : <String>{'protein_grams'};
        final value = nutrition_owner.NutritionTargetsData(
          caloriesKcal: 2100,
          proteinGrams: 135,
          carbohydrateGrams: 240,
          fatGrams: 65,
          fiberGrams: 30,
          customizationState: state,
          customizedFields: customizedFields,
          recommendationMetadata: const {'source': 'onboarding'},
        );

        await repository.upsert(value);
        final stored = await repository.read();

        expect(stored?.customizationState, state);
        expect(stored?.customizedFields, equals(customizedFields));
        expect(stored?.recommendationMetadata, {'source': 'onboarding'});
      }
    });

    test(
        'legacy Nutrition Target resume completes through canonical owners only',
        () async {
      final nutritionProfile =
          nutrition_owner.InMemoryNutritionProfileRepository();
      final nutritionTargets =
          nutrition_owner.InMemoryNutritionTargetsRepository();
      final initialDraft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.targets,
        profile: _validProfile(),
        nutrition: const NutritionOnboardingDraft(
          dietType: NutritionDietType.vegan,
          allergyRestrictions: {NutritionAllergyRestriction.none},
        ),
        workout: _validWorkout(),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.nutritionTarget,
          dailySteps: 9200,
          sleepTargetMinutes: 480,
          sleepTimeMinutes: 1320,
          wakeTimeMinutes: 360,
          waterMl: 2400,
          goalPaceKgPerWeek: 0.5,
        ),
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: initialDraft,
      );
      addTearDown(controller.dispose);

      expect(controller.state.stepId, OnboardingStepId.nutritionGoals);
      expect(
          controller.state.currentSection, OnboardingSectionId.nutritionGoals);

      final persist = _persistUseCase(
        nutritionProfileRepository: nutritionProfile,
        nutritionTargetsRepository: nutritionTargets,
      );
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.resumeDraft,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
      );

      await persist(draft: controller.state.draft, flowPlan: flowPlan);

      expect(await nutritionProfile.read(), isNotNull);
      expect(await nutritionTargets.read(), isNotNull);
    });

    test(
        'Nutrition Profile failure blocks later publication, retry succeeds, and completed retry is idempotent',
        () async {
      final nutritionProfile = _RecordingNutritionProfileRepository(
        failuresRemaining: 1,
      );
      final workoutProfile = _RecordingWorkoutProfileRepository();
      final workoutTargets = _RecordingWorkoutTargetsRepository();
      final nutritionTargets = _RecordingNutritionTargetsRepository();
      final appPreferences = _RecordingAppPreferencesRepository();
      final preference = _RecordingAppModePreference();
      final status = _RecordingOnboardingStatusRepository();
      final complete = _completeUseCase(
        nutritionProfileRepository: nutritionProfile,
        workoutProfileRepository: workoutProfile,
        workoutTargetsRepository: workoutTargets,
        nutritionTargetsRepository: nutritionTargets,
        appPreferencesRepository: appPreferences,
        preference: preference,
        status: status,
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
            OwnerPersistenceTarget.nutritionProfile,
          ),
        ),
      );

      expect(workoutProfile.upsertCalls, 0);
      expect(workoutTargets.upsertCalls, 0);
      expect(nutritionTargets.upsertCalls, 0);
      expect(appPreferences.upsertCalls, 0);
      expect(preference.writeCalls, 0);
      expect(status.completedWriteCalls, 0);

      await complete(draft: draft, flowPlan: flowPlan);

      expect(nutritionProfile.upsertCalls, 2);
      expect(workoutProfile.upsertCalls, 1);
      expect(workoutTargets.upsertCalls, 1);
      expect(nutritionTargets.upsertCalls, 1);
      expect(appPreferences.upsertCalls, 1);
      expect(preference.writeCalls, 1);
      expect(status.completedWriteCalls, 1);
      expect(status.status, OnboardingStatus.completed);

      await complete(draft: draft, flowPlan: flowPlan);

      expect(nutritionProfile.upsertCalls, 2);
      expect(workoutProfile.upsertCalls, 1);
      expect(workoutTargets.upsertCalls, 1);
      expect(nutritionTargets.upsertCalls, 1);
      expect(appPreferences.upsertCalls, 1);
      expect(preference.writeCalls, 1);
      expect(status.completedWriteCalls, 1);
    });

    test(
        'Workout Profile failure blocks Workout Targets, Nutrition Targets and publication',
        () async {
      final workoutProfile =
          _RecordingWorkoutProfileRepository(failuresRemaining: 1);
      final workoutTargets = _RecordingWorkoutTargetsRepository();
      final nutritionTargets = _RecordingNutritionTargetsRepository();
      final appPreferences = _RecordingAppPreferencesRepository();
      final preference = _RecordingAppModePreference();
      final status = _RecordingOnboardingStatusRepository();
      final complete = _completeUseCase(
        workoutProfileRepository: workoutProfile,
        workoutTargetsRepository: workoutTargets,
        nutritionTargetsRepository: nutritionTargets,
        appPreferencesRepository: appPreferences,
        preference: preference,
        status: status,
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
            OwnerPersistenceTarget.workoutProfile,
          ),
        ),
      );

      expect(workoutProfile.upsertCalls, 1);
      expect(workoutTargets.upsertCalls, 0);
      expect(nutritionTargets.upsertCalls, 0);
      expect(appPreferences.upsertCalls, 0);
      expect(preference.writeCalls, 0);
      expect(status.completedWriteCalls, 0);
    });

    test('Nutrition Targets failure blocks App Mode and completion publication',
        () async {
      final nutritionTargets = _RecordingNutritionTargetsRepository(
        failuresRemaining: 1,
      );
      final appPreferences = _RecordingAppPreferencesRepository();
      final preference = _RecordingAppModePreference();
      final status = _RecordingOnboardingStatusRepository();
      final complete = _completeUseCase(
        nutritionTargetsRepository: nutritionTargets,
        appPreferencesRepository: appPreferences,
        preference: preference,
        status: status,
      );
      final draft = _validDraft(mode: AppMode.nutrition);
      final flowPlan = const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
        workoutIntroChoice: null,
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

      expect(nutritionTargets.upsertCalls, 1);
      expect(appPreferences.upsertCalls, 0);
      expect(preference.writeCalls, 0);
      expect(status.completedWriteCalls, 0);
    });
  });
}

class _ModeCase {
  const _ModeCase({
    required this.mode,
    required this.expectNutritionProfile,
    required this.expectWorkout,
    this.workoutIntroChoice,
  });

  final AppMode mode;
  final WorkoutIntroChoice? workoutIntroChoice;
  final bool expectNutritionProfile;
  final bool expectWorkout;

  String get label =>
      '${mode.storageValue}/${workoutIntroChoice?.name ?? 'default'}';
}

class _AllergyCase {
  const _AllergyCase({
    required this.label,
    required this.draft,
    required this.expectedAllergies,
  });

  final String label;
  final NutritionOnboardingDraft draft;
  final Set<String>? expectedAllergies;
}

PersistOnboardingOwnerDataUseCase _persistUseCase({
  nutrition_owner.NutritionProfileRepository? nutritionProfileRepository,
  workout_owner.WorkoutProfileRepository? workoutProfileRepository,
  workout_owner.WorkoutTargetsRepository? workoutTargetsRepository,
  nutrition_owner.NutritionTargetsRepository? nutritionTargetsRepository,
}) {
  return PersistOnboardingOwnerDataUseCase(
    profileRepository: _MemoryUserProfileRepository(),
    bodyRepository: body_owner.InMemoryBodySetupRepository(),
    wellnessRepository: body_owner.InMemoryWellnessTargetsRepository(),
    nutritionProfileRepository: nutritionProfileRepository ??
        nutrition_owner.InMemoryNutritionProfileRepository(),
    workoutProfileRepository: workoutProfileRepository ??
        workout_owner.InMemoryWorkoutProfileRepository(),
    workoutTargetsRepository: workoutTargetsRepository ??
        workout_owner.InMemoryWorkoutTargetsRepository(),
    nutritionTargetsRepository: nutritionTargetsRepository ??
        nutrition_owner.InMemoryNutritionTargetsRepository(),
  );
}

CompleteOnboardingUseCase _completeUseCase({
  nutrition_owner.NutritionProfileRepository? nutritionProfileRepository,
  workout_owner.WorkoutProfileRepository? workoutProfileRepository,
  workout_owner.WorkoutTargetsRepository? workoutTargetsRepository,
  nutrition_owner.NutritionTargetsRepository? nutritionTargetsRepository,
  required _RecordingAppPreferencesRepository appPreferencesRepository,
  required _RecordingAppModePreference preference,
  required _RecordingOnboardingStatusRepository status,
}) {
  return CompleteOnboardingUseCase(
    confirmedModePreference: preference,
    appPreferencesRepository: appPreferencesRepository,
    statusRepository: status,
    persistOwnerDataUseCase: _persistUseCase(
      nutritionProfileRepository: nutritionProfileRepository,
      workoutProfileRepository: workoutProfileRepository,
      workoutTargetsRepository: workoutTargetsRepository,
      nutritionTargetsRepository: nutritionTargetsRepository,
    ),
    validator: const OnboardingCompletionValidator(
      hasDurableOwnerPersistence: true,
      backendUserReady: true,
    ),
  );
}

OnboardingDraft _validDraft({
  required AppMode mode,
  WorkoutIntroChoice? workoutIntroChoice,
  NutritionOnboardingDraft nutrition = const NutritionOnboardingDraft(
    dietType: NutritionDietType.vegan,
    allergyRestrictions: {NutritionAllergyRestriction.none},
  ),
}) {
  return OnboardingDraft(
    status: OnboardingStatus.inProgress,
    selectedMode: mode,
    workoutIntroChoice: workoutIntroChoice,
    goalSelection: const GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
    ),
    currentStepId: OnboardingStepId.review,
    profile: _validProfile(),
    nutrition: nutrition,
    workout: _validWorkout(),
    targets: const TargetsOnboardingDraft(
      currentStepId: TargetStepId.nutritionTarget,
      dailySteps: 9000,
      sleepTargetMinutes: 480,
      sleepTimeMinutes: 1320,
      wakeTimeMinutes: 360,
      waterMl: 2500,
      goalPaceKgPerWeek: 0.5,
    ),
  );
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    name: 'O5E User',
    gender: ProfileGender.female,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(1996, 6, 15),
    heightCm: 165,
    currentWeightKg: 60,
    targetWeightKg: 58,
    targetWeightDirection: GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {
      ProfileHealthCondition.hypertension,
      ProfileHealthCondition.other,
    },
    otherHealthCondition: 'Migraine',
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

class _RecordingNutritionProfileRepository
    implements nutrition_owner.NutritionProfileRepository {
  _RecordingNutritionProfileRepository({this.failuresRemaining = 0});

  int failuresRemaining;
  int upsertCalls = 0;
  nutrition_owner.NutritionProfileData? data;

  @override
  Future<nutrition_owner.NutritionProfileData?> read() async => data;

  @override
  Future<void> upsert(nutrition_owner.NutritionProfileData profile) async {
    upsertCalls += 1;
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw StateError('canonical Nutrition Profile write failed');
    }
    data = profile;
  }
}

class _RecordingWorkoutProfileRepository
    implements workout_owner.WorkoutProfileRepository {
  _RecordingWorkoutProfileRepository({this.failuresRemaining = 0});

  int failuresRemaining;
  int upsertCalls = 0;
  workout_owner.WorkoutProfileData? data;

  @override
  Future<workout_owner.WorkoutProfileData?> read() async => data;

  @override
  Future<void> upsert(workout_owner.WorkoutProfileData profile) async {
    upsertCalls += 1;
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw StateError('canonical Workout Profile write failed');
    }
    data = profile;
  }
}

class _RecordingWorkoutTargetsRepository
    implements workout_owner.WorkoutTargetsRepository {
  int upsertCalls = 0;
  workout_owner.WorkoutTargetsData? data;

  @override
  Future<workout_owner.WorkoutTargetsData?> read() async => data;

  @override
  Future<void> upsert(workout_owner.WorkoutTargetsData targets) async {
    upsertCalls += 1;
    targets.validate();
    data = targets;
  }
}

class _RecordingNutritionTargetsRepository
    implements nutrition_owner.NutritionTargetsRepository {
  _RecordingNutritionTargetsRepository({this.failuresRemaining = 0});

  int failuresRemaining;
  int upsertCalls = 0;
  nutrition_owner.NutritionTargetsData? data;

  @override
  Future<nutrition_owner.NutritionTargetsData?> read() async => data;

  @override
  Future<void> upsert(nutrition_owner.NutritionTargetsData targets) async {
    upsertCalls += 1;
    if (failuresRemaining > 0) {
      failuresRemaining -= 1;
      throw StateError('canonical Nutrition Targets write failed');
    }
    targets.validate();
    data = targets;
  }
}

class _RecordingAppPreferencesRepository implements AppPreferencesRepository {
  AppPreferencesState state = const AppPreferencesState.missing();
  int upsertCalls = 0;

  @override
  Future<AppPreferencesState> read() async => state;

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    upsertCalls += 1;
    state = AppPreferencesState.present(
      appMode: preferences.appMode,
      activeTabs: preferences.activeTabs,
    );
  }
}

class _RecordingAppModePreference implements AppModePreference {
  AppMode? storedMode;
  int writeCalls = 0;

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
    writeCalls += 1;
    storedMode = mode;
  }

  @override
  Future<void> clear() async {
    storedMode = null;
  }
}

class _RecordingOnboardingStatusRepository
    implements OnboardingStatusRepository {
  OnboardingStatus? status;
  bool initialized = false;
  int ensureInitializedCalls = 0;
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
    ensureInitializedCalls += 1;
    initialized = true;
  }

  @override
  Future<void> write(OnboardingStatus value) async {
    status = value;
    if (value == OnboardingStatus.completed) {
      completedWriteCalls += 1;
    }
  }

  @override
  Future<void> clear() async {
    status = null;
    initialized = false;
  }
}

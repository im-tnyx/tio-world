import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_profile/profile.dart' as profile_owner;
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  late profile_owner.InMemoryProfileSetupRepository profileRepo;
  late body_owner.InMemoryBodySetupRepository bodyRepo;
  late body_owner.InMemoryWellnessTargetsRepository wellnessRepo;
  late nutrition_owner.InMemoryNutritionProfileRepository nutritionProfileRepo;
  late workout_owner.InMemoryWorkoutProfileRepository workoutProfileRepo;
  late workout_owner.InMemoryWorkoutTargetsRepository workoutTargetsRepo;
  late nutrition_owner.InMemoryNutritionTargetsRepository nutritionTargetsRepo;
  late PersistOnboardingOwnerDataUseCase persistUseCase;

  setUp(() {
    profileRepo = profile_owner.InMemoryProfileSetupRepository();
    bodyRepo = body_owner.InMemoryBodySetupRepository();
    wellnessRepo = body_owner.InMemoryWellnessTargetsRepository();
    nutritionProfileRepo = nutrition_owner.InMemoryNutritionProfileRepository();
    workoutProfileRepo = workout_owner.InMemoryWorkoutProfileRepository();
    workoutTargetsRepo = workout_owner.InMemoryWorkoutTargetsRepository();
    nutritionTargetsRepo = nutrition_owner.InMemoryNutritionTargetsRepository();
    persistUseCase = PersistOnboardingOwnerDataUseCase(
      profileRepository: profileRepo,
      bodyRepository: bodyRepo,
      wellnessRepository: wellnessRepo,
      nutritionProfileRepository: nutritionProfileRepo,
      workoutProfileRepository: workoutProfileRepo,
      workoutTargetsRepository: workoutTargetsRepo,
      nutritionTargetsRepository: nutritionTargetsRepo,
    );
  });

  test('blocks completion when draft mode is missing', () async {
    final preference = _FakeAppModePreference();
    final repository = _FakeOnboardingStatusRepository();
    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
    );

    await expectLater(
      () => useCase(
        draft: OnboardingDraft(),
        flowPlan: const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: null,
          workoutIntroChoice: null,
        ),
      ),
      throwsA(isA<OnboardingCompletionBlockedException>()),
    );

    expect(preference.storedMode, isNull);
    expect(repository.status, isNull);
  });

  test(
      'blocks completion by default because in-memory repositories do not qualify as durable persistence',
      () async {
    final preference = _FakeAppModePreference();
    final repository = _FakeOnboardingStatusRepository();
    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
    );
    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      currentStepId: OnboardingStepId.review,
    );

    await expectLater(
      () => useCase(
        draft: draft,
        flowPlan: const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: AppMode.workout,
          workoutIntroChoice: null,
        ),
      ),
      throwsA(
        isA<OnboardingCompletionBlockedException>().having(
          (error) => error.eligibility.message,
          'message',
          contains('durable owner persistence'),
        ),
      ),
    );

    expect(preference.storedMode, isNull);
    expect(repository.status, isNull);
    expect(await profileRepo.getProfileSetup(), isNull);
    expect(bodyRepo.data, isNull);
    expect(wellnessRepo.data, isNull);
    expect(await nutritionProfileRepo.read(), isNull);
    expect(await workoutProfileRepo.read(), isNull);
    expect(await workoutTargetsRepo.read(), isNull);
    expect(await nutritionTargetsRepo.read(), isNull);
  });

  test(
      'blocks completion when user is unauthenticated even if durable owner persistence is enabled',
      () async {
    final preference = _FakeAppModePreference();
    final repository = _FakeOnboardingStatusRepository();
    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: false,
      ),
    );
    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      currentStepId: OnboardingStepId.review,
    );

    await expectLater(
      () => useCase(
        draft: draft,
        flowPlan: const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: AppMode.workout,
          workoutIntroChoice: null,
        ),
      ),
      throwsA(
        isA<OnboardingCompletionBlockedException>().having(
          (error) => error.eligibility.message,
          'message',
          contains('Sign in required'),
        ),
      ),
    );

    expect(preference.storedMode, isNull);
    expect(repository.status, isNull);
  });

  test(
      'atomic completion when durable owner persistence is explicitly enabled: owner writes -> confirmed mode write -> status completed',
      () async {
    final operations = <String>[];
    final preference = _FakeAppModePreference(operations: operations);
    final repository = _FakeOnboardingStatusRepository(operations: operations);
    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      goalSelection: const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      status: OnboardingStatus.inProgress,
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.workout,
      workoutIntroChoice: null,
    );

    await useCase(
      draft: draft,
      flowPlan: flowPlan,
    );

    expect(await profileRepo.getProfileSetup(), isNotNull);
    expect(bodyRepo.data, isNotNull);
    expect(wellnessRepo.data, isNotNull);
    expect(wellnessRepo.data?.dailySteps, 10000);
    expect(await nutritionProfileRepo.read(), isNull);
    expect(await workoutProfileRepo.read(), isNotNull);
    expect(await workoutTargetsRepo.read(), isNotNull);
    expect(await nutritionTargetsRepo.read(), isNotNull);
    expect(preference.storedMode, AppMode.workout);
    expect(repository.status, OnboardingStatus.completed);
    expect(
      operations,
      [
        'repository.ensureInitialized',
        'preference.write.workout',
        'repository.write.completed',
      ],
    );
  });

  test('owner persistence failure prevents confirmed mode and status writes',
      () async {
    final failingProfileRepo = _FailingProfileSetupRepo();
    final operations = <String>[];
    final preference = _FakeAppModePreference(operations: operations);
    final repository = _FakeOnboardingStatusRepository(operations: operations);
    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: PersistOnboardingOwnerDataUseCase(
        profileRepository: failingProfileRepo,
        bodyRepository: bodyRepo,
        wellnessRepository: wellnessRepo,
        nutritionProfileRepository: nutritionProfileRepo,
        workoutProfileRepository: workoutProfileRepo,
        workoutTargetsRepository: workoutTargetsRepo,
        nutritionTargetsRepository: nutritionTargetsRepo,
      ),
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      status: OnboardingStatus.inProgress,
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.workout,
      workoutIntroChoice: null,
    );

    await expectLater(
      () => useCase(draft: draft, flowPlan: flowPlan),
      throwsA(isA<OwnerPersistenceException>()),
    );

    expect(preference.storedMode, isNull);
    expect(repository.status, isNull);
    expect(operations, ['repository.ensureInitialized']);
  });

  test('confirmed mode write failure never marks onboarding completed',
      () async {
    final preference = _FakeAppModePreference(
      writeError: StateError('mode write failed'),
    );
    final repository = _FakeOnboardingStatusRepository();
    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    final draft = OnboardingDraft(
      selectedMode: AppMode.nutrition,
      profile: _validProfile(),
      targets: _validTargets(),
      status: OnboardingStatus.inProgress,
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.nutrition,
      workoutIntroChoice: null,
    );

    await expectLater(
      () => useCase(draft: draft, flowPlan: flowPlan),
      throwsStateError,
    );

    expect(preference.storedMode, isNull);
    expect(repository.status, isNull);
  });

  test('status write failure remains retryable and completes on retry',
      () async {
    final preference = _FakeAppModePreference();
    final repository = _FakeOnboardingStatusRepository(
      failCompletedWrites: 1,
    );
    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );
    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      status: OnboardingStatus.inProgress,
    );
    final flowPlan = const BuildOnboardingFlowUseCase()(
      entryPath: OnboardingEntryPath.firstRun,
      mode: AppMode.workout,
      workoutIntroChoice: null,
    );

    await expectLater(
      () => useCase(draft: draft, flowPlan: flowPlan),
      throwsStateError,
    );

    expect(preference.storedMode, AppMode.workout);
    expect(repository.status, isNull);

    await useCase(draft: draft, flowPlan: flowPlan);

    expect(preference.storedMode, AppMode.workout);
    expect(repository.status, OnboardingStatus.completed);
    expect(repository.writeCalls, 2);
  });

  test('already completed state is idempotent when confirmed mode exists',
      () async {
    final preference = _FakeAppModePreference(initialMode: AppMode.workout);
    final repository = _FakeOnboardingStatusRepository(
      initialStatus: OnboardingStatus.completed,
      hasStoredContractVersion: true,
    );
    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    await useCase(
      draft: OnboardingDraft(
        selectedMode: AppMode.workout,
        status: OnboardingStatus.completed,
      ),
      flowPlan: const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        workoutIntroChoice: null,
      ),
    );

    expect(repository.ensureInitializedCalls, 0);
    expect(repository.writeCalls, 0);
    expect(preference.writeCalls, 0);
  });

  test(
      'finalizer is executed before confirmed mode write and status completed write',
      () async {
    final operations = <String>[];
    final preference = _FakeAppModePreference(operations: operations);
    final repository = _FakeOnboardingStatusRepository(operations: operations);
    final fakeFinalizer = _FakeOnboardingRemoteFinalizer(operations: operations);

    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      finalizer: fakeFinalizer,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      currentStepId: OnboardingStepId.review,
    );

    await useCase(
      draft: draft,
      flowPlan: const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        workoutIntroChoice: null,
      ),
    );

    expect(operations, [
      'repository.ensureInitialized',
      'finalizer.finalize',
      'preference.write.workout',
      'repository.write.completed',
    ]);
  });

  test(
      'when finalizer fails, confirmed mode and completed status are NOT written',
      () async {
    final operations = <String>[];
    final preference = _FakeAppModePreference(operations: operations);
    final repository = _FakeOnboardingStatusRepository(operations: operations);
    final fakeFinalizer = _FakeOnboardingRemoteFinalizer(
      operations: operations,
      errorToThrow: Exception('Server finalizer error'),
    );

    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      finalizer: fakeFinalizer,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      currentStepId: OnboardingStepId.review,
    );

    await expectLater(
      () => useCase(
        draft: draft,
        flowPlan: const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: AppMode.workout,
          workoutIntroChoice: null,
        ),
      ),
      throwsA(isA<Exception>()),
    );

    expect(preference.storedMode, isNull);
    expect(repository.status, isNull);
    expect(operations, [
      'repository.ensureInitialized',
      'finalizer.finalize',
    ]);
  });

  test('clears unfinished onboarding draft on successful completion', () async {
    final preference = _FakeAppModePreference();
    final repository = _FakeOnboardingStatusRepository();
    final draftRepo = InMemoryOnboardingDraftRepository(
      initialSnapshot: OnboardingDraftSnapshot(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
      ),
    );

    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      draftRepository: draftRepo,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      currentStepId: OnboardingStepId.review,
    );

    await useCase(
      draft: draft,
      flowPlan: const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        workoutIntroChoice: null,
      ),
    );

    expect(preference.storedMode, AppMode.workout);
    expect(repository.status, OnboardingStatus.completed);
    expect(await draftRepo.loadDraft(), isNull);
  });

  test('does not clear draft if completion validation fails', () async {
    final preference = _FakeAppModePreference();
    final repository = _FakeOnboardingStatusRepository();
    final initialSnapshot = OnboardingDraftSnapshot(
      draft: OnboardingDraft(selectedMode: AppMode.workout),
    );
    final draftRepo = InMemoryOnboardingDraftRepository(
      initialSnapshot: initialSnapshot,
    );

    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      draftRepository: draftRepo,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: false,
        backendUserReady: false,
      ),
    );
    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      currentStepId: OnboardingStepId.review,
    );

    await expectLater(
      () => useCase(
        draft: draft,
        flowPlan: const BuildOnboardingFlowUseCase()(
          entryPath: OnboardingEntryPath.firstRun,
          mode: AppMode.workout,
          workoutIntroChoice: null,
        ),
      ),
      throwsA(isA<OnboardingCompletionBlockedException>()),
    );

    expect(await draftRepo.loadDraft(), equals(initialSnapshot));
  });

  test('completion succeeds even if draft clear fails', () async {
    final preference = _FakeAppModePreference();
    final repository = _FakeOnboardingStatusRepository();
    final draftRepo = InMemoryOnboardingDraftRepository(
      initialSnapshot: OnboardingDraftSnapshot(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
      ),
    )..shouldFailOnClear = true;

    final useCase = CompleteOnboardingUseCase(
      confirmedModePreference: preference,
      statusRepository: repository,
      persistOwnerDataUseCase: persistUseCase,
      draftRepository: draftRepo,
      validator: const OnboardingCompletionValidator(
        hasDurableOwnerPersistence: true,
        backendUserReady: true,
      ),
    );

    final draft = OnboardingDraft(
      selectedMode: AppMode.workout,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: _validTargets(),
      currentStepId: OnboardingStepId.review,
    );

    await useCase(
      draft: draft,
      flowPlan: const BuildOnboardingFlowUseCase()(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
        workoutIntroChoice: null,
      ),
    );

    expect(preference.storedMode, AppMode.workout);
    expect(repository.status, OnboardingStatus.completed);
  });
}

class _FailingProfileSetupRepo implements profile_owner.ProfileSetupRepository {
  @override
  Stream<profile_owner.ProfileSetupData?> watchProfileSetup() async* {
    yield null;
  }

  @override
  Future<void> saveProfileSetup(profile_owner.ProfileSetupData data) async {
    throw StateError('Disk write error');
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

class _FakeOnboardingStatusRepository implements OnboardingStatusRepository {
  _FakeOnboardingStatusRepository({
    this.initialStatus,
    this.hasStoredContractVersion = false,
    this.failCompletedWrites = 0,
    List<String>? operations,
  }) : _operations = operations;

  final OnboardingStatus? initialStatus;
  final List<String>? _operations;
  int failCompletedWrites;
  OnboardingStatus? status;
  bool hasStoredContractVersion;
  int ensureInitializedCalls = 0;
  int writeCalls = 0;

  @override
  Future<void> clear() async {
    status = null;
    hasStoredContractVersion = false;
  }

  @override
  Future<void> ensureInitialized() async {
    ensureInitializedCalls++;
    hasStoredContractVersion = true;
    _operations?.add('repository.ensureInitialized');
  }

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return OnboardingStatusSnapshot(
      status: status ?? initialStatus,
      hasStoredContractVersion: hasStoredContractVersion,
    );
  }

  @override
  Future<void> write(OnboardingStatus status) async {
    writeCalls++;
    if (status == OnboardingStatus.completed && failCompletedWrites > 0) {
      failCompletedWrites--;
      throw StateError('status write failed');
    }
    this.status = status;
    _operations?.add('repository.write.${status.name}');
  }
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference({
    AppMode? initialMode,
    this.writeError,
    List<String>? operations,
  })  : storedMode = initialMode,
        _operations = operations;

  final Object? writeError;
  final List<String>? _operations;
  AppMode? storedMode;
  int writeCalls = 0;

  @override
  Future<void> clear() async {
    storedMode = null;
  }

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
    writeCalls++;
    if (writeError case final error?) throw error;
    storedMode = mode;
    _operations?.add('preference.write.${mode.name}');
  }
}

class _FakeOnboardingRemoteFinalizer implements OnboardingRemoteFinalizer {
  _FakeOnboardingRemoteFinalizer({
    this.operations,
    this.errorToThrow,
  });

  final List<String>? operations;
  final Object? errorToThrow;

  @override
  Future<void> finalize() async {
    operations?.add('finalizer.finalize');
    if (errorToThrow != null) {
      throw errorToThrow!;
    }
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

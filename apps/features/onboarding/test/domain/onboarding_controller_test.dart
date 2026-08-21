import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('legacy mode selection enters the active product plan without completing',
      () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
    );

    controller.selectMode(AppMode.hybrid);

    expect(controller.state.draft.selectedMode, AppMode.hybrid);
    expect(controller.state.draft.status, OnboardingStatus.inProgress);
    expect(controller.state.draft.status, isNot(OnboardingStatus.completed));
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.currentSection, OnboardingSectionId.profile);
    expect(controller.state.flowPlan.steps, hasLength(5));
    expect(
      controller.state.flowPlan.stepIds,
      isNot(contains(OnboardingStepId.mode)),
    );
  });

  test('each mode selection rebuilds the matching active typed plan', () {
    final expectedSteps = {
      AppMode.workout: const [
        OnboardingStepId.profileBasics,
        OnboardingStepId.workoutPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
      AppMode.nutrition: const [
        OnboardingStepId.profileBasics,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
      AppMode.hybrid: const [
        OnboardingStepId.profileBasics,
        OnboardingStepId.workoutIntro,
        OnboardingStepId.workoutPreferences,
        OnboardingStepId.targets,
        OnboardingStepId.review,
      ],
    };

    for (final mode in AppMode.values) {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
      )..selectMode(mode);

      expect(controller.state.draft.selectedMode, mode);
      expect(controller.state.flowPlan.stepIds, expectedSteps[mode]);
      expect(controller.state.draft.status, isNot(OnboardingStatus.completed));
    }
  });

  test('next and previous update stable Product Onboarding step identity',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(),
      ),
    );

    await controller.next(onFinish: _completeImmediately);

    expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
    expect(controller.state.currentSection, OnboardingSectionId.workout);
    expect(
      controller.state.completedStepIds,
      contains(OnboardingStepId.profileBasics),
    );
    expect(controller.state.canGoBack, isTrue);

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
  });

  test('mode change reconciles an ineligible step to nearest previous step',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        currentStepId: OnboardingStepId.workoutIntro,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        profile: _validProfile(),
        workout: _validWorkout(),
        completedStepIds: const {
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
        },
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.workoutIntro);

    controller.selectMode(AppMode.workout);

    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(
      controller.state.completedStepIds,
      isNot(contains(OnboardingStepId.workoutIntro)),
    );
  });

  test('invalid restored step reconciles safely to Profile', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.workoutIntro,
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.profileBasics);
  });

  test('legacy profile goals migrate only through meaning-preserving mappings', () {
    final workout = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(currentStepId: ProfileStepId.healthConditions),
      ),
    );
    expect(
      workout.state.draft.goalSelection,
      const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
    );
    expect(
      workout.state.draft.profile.currentStepId,
      ProfileStepId.healthConditions,
    );

    final nutrition = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.targets,
        completedStepIds: const {OnboardingStepId.profileBasics},
        profile: _validProfile(
          currentStepId: ProfileStepId.healthConditions,
          goals: const {ProfileGoal.buildMuscle},
        ),
      ),
    );
    expect(nutrition.state.stepId, OnboardingStepId.profileBasics);
    expect(nutrition.state.draft.profile.currentStepId, ProfileStepId.goal);
    expect(nutrition.state.draft.goalSelection, const GoalIntentSelection());
  });

  test('goal step validates ordered mode-aware selection', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.goal,
          name: 'Tio User',
          gender: ProfileGender.other,
        ),
      ),
    );

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.validationErrors['goal'], 'Choose your main goal.');

    controller.tapGoalIntent(GoalIntent.buildMuscle);
    controller.tapGoalIntent(GoalIntent.getStronger);
    expect(
      controller.state.draft.goalSelection,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.buildMuscle,
        supportingGoal: GoalIntent.getStronger,
      ),
    );

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.age);
  });

  test('nutrition goal taps remain single-select', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(currentStepId: ProfileStepId.goal),
      ),
    );

    controller.tapGoalIntent(GoalIntent.loseWeight);
    controller.tapGoalIntent(GoalIntent.gainWeight);

    expect(
      controller.state.draft.goalSelection,
      const GoalIntentSelection(primaryGoal: GoalIntent.gainWeight),
    );
  });

  test('validation errors disable continue until cleared', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
      ),
    );

    controller.setValidationErrors(const {'name': 'Enter your name'});
    expect(controller.state.canContinue, isFalse);

    controller.setValidationErrors(const {});
    expect(controller.state.canContinue, isTrue);
  });

  test('hybrid workout intro choice drives the next branch and progress',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.workoutIntro,
        profile: _validProfile(),
      ),
    );

    expect(controller.state.canContinue, isFalse);
    expect(controller.state.progressStepCount, 26);

    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.later);

    expect(controller.state.canContinue, isTrue);
    expect(controller.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);
    expect(
      controller.state.flowPlan.stepIds,
      isNot(contains(OnboardingStepId.workoutPreferences)),
    );
    expect(controller.state.progressStepCount, 18);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.targets);

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.workoutIntro);
    expect(controller.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);

    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.setupNow);
    expect(
      controller.state.flowPlan.stepIds,
      contains(OnboardingStepId.workoutPreferences),
    );
    expect(controller.state.progressStepCount, 26);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
  });

  test('mode change away from hybrid clears workout intro choice', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        currentStepId: OnboardingStepId.workoutIntro,
        profile: _validProfile(),
      ),
    );

    controller.selectMode(AppMode.workout);

    expect(controller.state.draft.workoutIntroChoice, isNull);
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
  });

  test('profile child navigation validates and completes only at the end',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
      ),
    );

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.name);
    expect(controller.state.validationErrors, contains('name'));
    expect(
      controller.state.completedStepIds,
      isNot(contains(OnboardingStepId.profileBasics)),
    );

    controller.updateProfileName('Tio User');
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.gender);

    controller.updateProfileGender(ProfileGender.other);
    await controller.next(onFinish: _completeImmediately);
    controller.tapGoalIntent(GoalIntent.stayFit);
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileDateOfBirth(DateTime(2000, 1, 1));
    await controller.next(onFinish: _completeImmediately);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.measurementUnits,
    );
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileHeight(171);
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileCurrentWeight(70);
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileTargetWeight(68);
    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileActivity(ProfileActivityLevel.active);
    await controller.next(onFinish: _completeImmediately);

    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.healthConditions,
    );
    expect(
      controller.state.completedStepIds,
      isNot(contains(OnboardingStepId.profileBasics)),
    );

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
    expect(
      controller.state.completedStepIds,
      contains(OnboardingStepId.profileBasics),
    );
  });

  test('profile Back moves Gender to Name and Name remains Product root', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.gender,
          name: 'Tio User',
        ),
      ),
    );

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.name);

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.name);
    expect(controller.state.canGoBack, isFalse);
  });

  test('final profile child follows each mode plan and mode switch keeps data',
      () async {
    for (final entry in {
      AppMode.workout: OnboardingStepId.workoutPreferences,
      AppMode.hybrid: OnboardingStepId.workoutIntro,
      AppMode.nutrition: OnboardingStepId.targets,
    }.entries) {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: OnboardingDraft(
          selectedMode: entry.key,
          goalSelection: GoalIntentSelection(
            primaryGoal: entry.key == AppMode.nutrition
                ? GoalIntent.maintainWeight
                : GoalIntent.stayFit,
          ),
          currentStepId: OnboardingStepId.profileBasics,
          profile: _validProfile(),
        ),
      );

      await controller.next(onFinish: _completeImmediately);
      expect(controller.state.stepId, entry.value);
    }

    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(currentStepId: ProfileStepId.name),
      ),
    );
    controller.previous();
    controller.selectMode(AppMode.nutrition);

    expect(controller.state.draft.profile.name, 'Tio User');
    expect(controller.state.draft.profile.heightCm, 171);
    expect(controller.state.draft.profile.goals, {ProfileGoal.keepFit});
    expect(controller.state.draft.goalSelection, const GoalIntentSelection());
  });

  test('progress reflects Product Onboarding screens and reaches 1.0 on review',
      () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(),
    );

    expect(controller.state.progressStepCount, 0);
    expect(controller.state.progressStepNumber, 0);
    expect(controller.state.progressValue, 0);

    controller.selectMode(AppMode.hybrid);
    controller.tapGoalIntent(GoalIntent.loseWeight);
    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.setupNow);
    expect(controller.state.progressStepCount, 26);
    expect(controller.state.progressStepNumber, 1);
    expect(controller.state.progressValue, closeTo(1 / 26, 0.0001));

    final reviewController = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        currentStepId: OnboardingStepId.review,
        profile: _validProfile(),
        workout: _validWorkout(),
      ),
    );
    expect(reviewController.state.progressStepNumber, 26);
    expect(reviewController.state.progressValue, 1.0);
  });

  test(
      'child movement inside Profile, Workout, and Targets increases global progress monotonically',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.name,
          name: 'Tio User',
        ),
        workout: _validWorkout(),
      ),
    );

    expect(controller.state.progressStepCount, 25);
    expect(controller.state.progressStepNumber, 1);
    expect(controller.state.progressValue, closeTo(1 / 25, 0.0001));

    await controller.next(onFinish: _completeImmediately);

    expect(controller.state.draft.profile.currentStepId, ProfileStepId.gender);
    expect(controller.state.progressStepCount, 25);
    expect(controller.state.progressStepNumber, 2);
    expect(controller.state.progressValue, closeTo(2 / 25, 0.0001));
  });

  test('updateDailyStepTarget updates target in draft', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.targets,
      ),
    );

    controller.updateDailyStepTarget(10000);
    expect(controller.state.draft.targets.dailySteps, 10000);
  });

  test('updateSleepSchedule updates schedule in draft', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.targets,
      ),
    );

    controller.updateSleepSchedule(
      durationMinutes: 480,
      sleepTimeMinutes: 1380,
      wakeTimeMinutes: 420,
    );
    expect(controller.state.draft.targets.sleepTargetMinutes, 480);
    expect(controller.state.draft.targets.sleepTimeMinutes, 1380);
    expect(controller.state.draft.targets.wakeTimeMinutes, 420);
  });

  test('updateWaterTargetMl updates millilitres in draft', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.targets,
      ),
    );

    controller.updateWaterTargetMl(3000);
    expect(controller.state.draft.targets.waterMl, 3000);
  });

  test('updateGoalPaceKgPerWeek updates pace in draft', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.targets,
      ),
    );

    controller.updateGoalPaceKgPerWeek(0.75);
    expect(controller.state.draft.targets.goalPaceKgPerWeek, 0.75);
  });

  test('target child navigation moves cleanly through all target steps', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.targets,
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.bridge,
        ),
      ),
    );

    expect(controller.state.draft.targets.currentStepId, TargetStepId.bridge);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.stepTarget);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.sleepTarget);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.waterTarget);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.goalPace);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.nutritionTarget);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.review);
  });

  test('target back navigation moves backward through target children', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.targets,
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.waterTarget,
        ),
      ),
    );

    controller.previous();
    expect(controller.state.draft.targets.currentStepId, TargetStepId.sleepTarget);
    controller.previous();
    expect(controller.state.draft.targets.currentStepId, TargetStepId.stepTarget);
    controller.previous();
    expect(controller.state.draft.targets.currentStepId, TargetStepId.bridge);
    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
  });

  test('target validation errors block continue until resolved', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        currentStepId: OnboardingStepId.targets,
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.waterTarget,
          waterMl: 500,
        ),
      ),
    );

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.validationErrors, contains('waterTarget'));
    expect(controller.state.canContinue, isFalse);

    controller.updateWaterTargetMl(2500);
    expect(controller.state.canContinue, isTrue);
  });

  test('duplicate finish calls are locked and failures keep draft retryable',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        profile: _validProfile(),
        workout: _validWorkout(),
      ),
      completionValidator: const _AlwaysEligibleValidator(),
    )..selectMode(AppMode.workout);
    while (controller.state.stepId != OnboardingStepId.review) {
      await controller.next(onFinish: _completeImmediately);
    }

    final finishGate = Completer<void>();
    var finishCalls = 0;
    Future<void> finish(OnboardingDraft _) {
      finishCalls++;
      return finishGate.future;
    }

    final first = controller.next(onFinish: finish);
    final second = controller.next(onFinish: finish);
    expect(finishCalls, 1);
    expect(controller.state.isCompleting, isTrue);

    finishGate.completeError(StateError('finish failed'));
    await Future.wait([first, second]);

    expect(controller.state.isCompleting, isFalse);
    expect(controller.state.retryableError, isA<StateError>());
    expect(controller.state.draft.status, OnboardingStatus.inProgress);
  });
}

class _AlwaysEligibleValidator extends OnboardingCompletionValidator {
  const _AlwaysEligibleValidator();

  @override
  OnboardingCompletionEligibility evaluate({
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
  }) {
    return OnboardingCompletionEligibility.eligible;
  }
}

Future<void> _completeImmediately(OnboardingDraft _) async {}

ProfileOnboardingDraft _validProfile({
  ProfileStepId currentStepId = ProfileStepId.healthConditions,
  Set<ProfileGoal> goals = const {ProfileGoal.keepFit},
}) {
  return ProfileOnboardingDraft(
    currentStepId: currentStepId,
    name: 'Tio User',
    gender: ProfileGender.other,
    goals: goals,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 70,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _validWorkout({
  WorkoutStepId currentStepId = WorkoutStepId.gymAccess,
}) {
  return WorkoutOnboardingDraft(
    currentStepId: currentStepId,
    gymAccess: WorkoutGymAccess.gym,
    experienceLevel: WorkoutExperienceLevel.beginner,
    focusAreas: const {WorkoutFocusArea.legs},
    trainingDays: const {
      WorkoutTrainingDay.monday,
      WorkoutTrainingDay.wednesday,
    },
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.auto,
  );
}

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
    expect(controller.state.currentSection, OnboardingSectionId.userProfile);
    expect(controller.state.flowPlan.steps, hasLength(10));
    expect(
      controller.state.flowPlan.stepIds,
      containsAllInOrder(const [
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.nutritionProfile,
        OnboardingStepId.workoutIntro,
        OnboardingStepId.workoutProfile,
        OnboardingStepId.workoutTargets,
        OnboardingStepId.wellnessGoals,
        OnboardingStepId.nutritionGoals,
      ]),
    );
    expect(
      controller.state.flowPlan.stepIds,
      isNot(contains(OnboardingStepId.mode)),
    );
  });

  test('each mode selection rebuilds the matching active typed plan', () {
    final expectedSteps = {
      AppMode.workout: const [
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.workoutProfile,
        OnboardingStepId.workoutTargets,
        OnboardingStepId.healthConnections,
        OnboardingStepId.review,
      ],
      AppMode.nutrition: const [
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.nutritionProfile,
        OnboardingStepId.wellnessGoals,
        OnboardingStepId.nutritionGoals,
        OnboardingStepId.healthConnections,
        OnboardingStepId.review,
      ],
      AppMode.hybrid: const [
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.nutritionProfile,
        OnboardingStepId.workoutIntro,
        OnboardingStepId.workoutProfile,
        OnboardingStepId.workoutTargets,
        OnboardingStepId.wellnessGoals,
        OnboardingStepId.nutritionGoals,
        OnboardingStepId.healthConnections,
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

  test('common Profile completes into Body Goal and Back restores final Profile child',
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

    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(controller.state.currentSection, OnboardingSectionId.bodyGoal);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.goal);
    expect(
      controller.state.completedStepIds,
      contains(OnboardingStepId.profileBasics),
    );
    expect(controller.state.canGoBack, isTrue);

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.healthConditions,
    );
  });

  test('live mode change reconciles an ineligible step to nearest previous step',
      () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        currentStepId: OnboardingStepId.workoutIntro,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        profile: _validProfile(),
        workout: _validWorkout(),
        completedStepIds: const {
          OnboardingStepId.profileBasics,
          OnboardingStepId.bodyGoal,
        },
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.workoutIntro);

    controller.selectMode(AppMode.workout);

    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.currentWeight);
    expect(
      controller.state.completedStepIds,
      isNot(contains(OnboardingStepId.workoutIntro)),
    );
  });

  test('stale Workout Wellness resume advances to Workout Profile', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.wellnessGoals,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: const TargetsOnboardingDraft(
          dailySteps: 12000,
          waterMl: 3000,
        ),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.workoutProfile);
    expect(controller.state.draft.workout.currentStepId, WorkoutStepId.gymAccess);
    expect(controller.state.draft.targets.dailySteps, 12000);
    expect(controller.state.draft.targets.waterMl, 3000);
  });

  test('stale Workout Nutrition Target resume advances to Health Connections', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.nutritionGoals,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        profile: _validProfile(),
        workout: _validWorkout(),
        targets: const TargetsOnboardingDraft(dailySteps: 10000),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.healthConnections);
    expect(controller.state.draft.targets.dailySteps, 10000);
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

  test('legacy profileBasics Goal child resumes in canonical Body Goal', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        profile: _validProfile(currentStepId: ProfileStepId.goal),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(controller.state.currentSection, OnboardingSectionId.bodyGoal);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.goal);
    expect(controller.state.draft.profile.currentWeightKg, 70);
    expect(controller.state.draft.profile.targetWeightKg, 70);
  });

  test('legacy profileBasics Current Weight child resumes without data loss', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        profile: _validProfile(currentStepId: ProfileStepId.currentWeight),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.currentWeight,
    );
    expect(controller.state.draft.profile.currentWeightKg, 70);
  });

  test('legacy eligible Target Weight child resumes in Body Goal', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.targetWeight,
          name: 'Tio User',
          gender: ProfileGender.other,
          dateOfBirth: DateTime(2000, 1, 1),
          heightCm: 171,
          currentWeightKg: 70,
          targetWeightKg: 65,
          targetWeightDirection: GoalWeightDirection.loss,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: const {ProfileHealthCondition.none},
        ),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.targetWeight);
    expect(controller.state.draft.profile.targetWeightKg, 65);
    expect(
      controller.state.draft.profile.targetWeightDirection,
      GoalWeightDirection.loss,
    );
  });

  test('legacy ineligible Target Weight child clamps to Current Weight', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        profile: _validProfile(currentStepId: ProfileStepId.targetWeight),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.currentWeight,
    );
    expect(controller.state.draft.profile.currentWeightKg, 70);
  });

  test('legacy common Profile child stays in userProfile section', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(currentStepId: ProfileStepId.healthConditions),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.profileBasics);
    expect(controller.state.currentSection, OnboardingSectionId.userProfile);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.healthConditions,
    );
  });

  test('legacy monolithic Targets checkpoint preserves forward progress by mode', () {
    final workout = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.targets,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.healthConditions,
          name: 'Tio User',
          gender: ProfileGender.other,
          dateOfBirth: DateTime(2000, 1, 1),
          heightCm: 171,
          currentWeightKg: 70,
          targetWeightKg: 65,
          targetWeightDirection: GoalWeightDirection.loss,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: const {ProfileHealthCondition.none},
        ),
      ),
    );

    expect(workout.state.stepId, OnboardingStepId.healthConnections);
    expect(workout.state.draft.profile.currentWeightKg, 70);
    expect(workout.state.draft.profile.targetWeightKg, 65);

    final nutrition = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.targets,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.healthConditions,
          name: 'Tio User',
          gender: ProfileGender.other,
          dateOfBirth: DateTime(2000, 1, 1),
          heightCm: 171,
          currentWeightKg: 70,
          targetWeightKg: 65,
          targetWeightDirection: GoalWeightDirection.loss,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: const {ProfileHealthCondition.none},
        ),
      ),
    );

    expect(nutrition.state.stepId, OnboardingStepId.wellnessGoals);
    expect(nutrition.state.draft.targets.currentStepId, TargetStepId.bridge);
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
    expect(nutrition.state.stepId, OnboardingStepId.bodyGoal);
    expect(nutrition.state.draft.profile.currentStepId, ProfileStepId.goal);
    expect(nutrition.state.draft.goalSelection, const GoalIntentSelection());
  });

  test('Body Goal validates ordered mode-aware Goal selection', () async {
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

    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
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
    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.currentWeight,
    );
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

    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
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
    expect(controller.state.progressStepCount, 29);

    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.later);

    expect(controller.state.canContinue, isTrue);
    expect(controller.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);
    expect(
      controller.state.flowPlan.stepIds,
      isNot(contains(OnboardingStepId.workoutPreferences)),
    );
    expect(controller.state.progressStepCount, 21);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.wellnessGoals);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.bridge);

    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.workoutIntro);
    expect(controller.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);

    controller.selectWorkoutIntroChoice(WorkoutIntroChoice.setupNow);
    expect(
      controller.state.flowPlan.stepIds,
      contains(OnboardingStepId.workoutPreferences),
    );
    expect(controller.state.progressStepCount, 29);

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
  });

  test('mode change away from hybrid clears workout intro choice', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        currentStepId: OnboardingStepId.workoutIntro,
        profile: _validProfile(),
      ),
    );

    controller.selectMode(AppMode.workout);

    expect(controller.state.draft.workoutIntroChoice, isNull);
    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.currentWeight);
  });

  test('common Profile and Body Goal complete into Workout Profile in Workout mode',
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

    controller.updateProfileName('Tio User');
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.gender);

    controller.updateProfileGender(ProfileGender.other);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.age);

    controller.updateProfileDateOfBirth(DateTime(2000, 1, 1));
    await controller.next(onFinish: _completeImmediately);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.measurementUnits,
    );

    await controller.next(onFinish: _completeImmediately);
    controller.updateProfileHeight(171);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.activity);

    controller.updateProfileActivity(ProfileActivityLevel.active);
    await controller.next(onFinish: _completeImmediately);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.healthConditions,
    );

    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.bodyGoal);
    expect(controller.state.draft.profile.currentStepId, ProfileStepId.goal);

    controller.tapGoalIntent(GoalIntent.stayFit);
    await controller.next(onFinish: _completeImmediately);
    expect(
      controller.state.draft.profile.currentStepId,
      ProfileStepId.currentWeight,
    );

    controller.updateProfileCurrentWeight(70);
    await controller.next(onFinish: _completeImmediately);

    expect(controller.state.stepId, OnboardingStepId.workoutProfile);
    expect(controller.state.draft.workout.currentStepId, WorkoutStepId.gymAccess);
    expect(
      controller.state.completedStepIds,
      containsAll(const [
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
      ]),
    );
    expect(
      controller.state.completedStepIds,
      isNot(contains(OnboardingStepId.wellnessGoals)),
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

  test('final common Profile child always enters Body Goal and mode switch keeps data',
      () async {
    for (final mode in AppMode.values) {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: OnboardingDraft(
          selectedMode: mode,
          goalSelection: GoalIntentSelection(
            primaryGoal: mode == AppMode.nutrition
                ? GoalIntent.maintainWeight
                : GoalIntent.stayFit,
          ),
          currentStepId: OnboardingStepId.profileBasics,
          profile: _validProfile(),
        ),
      );

      await controller.next(onFinish: _completeImmediately);
      expect(controller.state.stepId, OnboardingStepId.bodyGoal);
      expect(controller.state.draft.profile.currentStepId, ProfileStepId.goal);
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
    expect(controller.state.progressStepCount, 29);
    expect(controller.state.progressStepNumber, 1);
    expect(controller.state.progressValue, closeTo(1 / 29, 0.0001));

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
    expect(reviewController.state.progressStepNumber, 29);
    expect(reviewController.state.progressValue, 1.0);
  });

  test('child movement in Workout mode uses the shorter exact progress plan',
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

    expect(controller.state.progressStepCount, 21);
    expect(controller.state.progressStepNumber, 1);
    expect(controller.state.progressValue, closeTo(1 / 21, 0.0001));

    await controller.next(onFinish: _completeImmediately);

    expect(controller.state.draft.profile.currentStepId, ProfileStepId.gender);
    expect(controller.state.progressStepCount, 21);
    expect(controller.state.progressStepNumber, 2);
    expect(controller.state.progressValue, closeTo(2 / 21, 0.0001));
  });

  test('Wellness target updates remain available in Nutrition flow', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.wellnessGoals,
      ),
    );

    controller.updateDailyStepTarget(10000);
    controller.updateSleepSchedule(
      durationMinutes: 480,
      sleepTimeMinutes: 1380,
      wakeTimeMinutes: 420,
    );
    controller.updateWaterTargetMl(3000);

    expect(controller.state.draft.targets.dailySteps, 10000);
    expect(controller.state.draft.targets.sleepTargetMinutes, 480);
    expect(controller.state.draft.targets.sleepTimeMinutes, 1380);
    expect(controller.state.draft.targets.wakeTimeMinutes, 420);
    expect(controller.state.draft.targets.waterMl, 3000);
  });

  test('Goal Pace update remains Body Goal-owned', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.bodyGoal,
        profile: _validProfile(currentStepId: ProfileStepId.goalPace),
      ),
    );

    controller.updateGoalPaceKgPerWeek(0.75);
    expect(controller.state.draft.targets.goalPaceKgPerWeek, 0.75);
  });

  test('Wellness child navigation follows Nutrition Profile and enters Nutrition Target',
      () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        currentStepId: OnboardingStepId.wellnessGoals,
        profile: _validProfile(),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.bridge,
        ),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.wellnessGoals);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.bridge);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.stepTarget);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.sleepTarget);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.draft.targets.currentStepId, TargetStepId.waterTarget);
    await controller.next(onFinish: _completeImmediately);
    expect(controller.state.stepId, OnboardingStepId.nutritionGoals);
    expect(
      controller.state.completedStepIds,
      contains(OnboardingStepId.wellnessGoals),
    );
  });

  test('Wellness Back returns to Nutrition Profile after the Bridge', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.wellnessGoals,
        profile: _validProfile(),
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.waterTarget,
        ),
      ),
    );

    expect(controller.state.stepId, OnboardingStepId.wellnessGoals);
    controller.previous();
    expect(controller.state.draft.targets.currentStepId, TargetStepId.sleepTarget);
    controller.previous();
    expect(controller.state.draft.targets.currentStepId, TargetStepId.stepTarget);
    controller.previous();
    expect(controller.state.draft.targets.currentStepId, TargetStepId.bridge);
    controller.previous();
    expect(controller.state.stepId, OnboardingStepId.nutritionProfile);
    expect(
      controller.state.draft.nutrition.currentStepId,
      NutritionProfileStepId.allergiesRestrictions,
    );
  });

  test('Wellness validation errors block continue until resolved', () async {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.firstRun,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
        ),
        currentStepId: OnboardingStepId.wellnessGoals,
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
        status: OnboardingStatus.inProgress,
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
        currentStepId: OnboardingStepId.profileBasics,
        profile: _validProfile(),
        workout: _validWorkout(),
      ),
      completionValidator: const _AlwaysEligibleValidator(),
    );
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

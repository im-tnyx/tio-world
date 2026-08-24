import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const policy = WeightGoalFlowPolicy();
  final cases = _acceptanceCases();

  test('legacy Goal Pace cursors reconcile into Body Goal by mode and goal', () {
    for (final testCase in cases) {
      final explicitDirection = policy.directionFor(
        mode: testCase.mode,
        selection: testCase.selection,
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: testCase.mode,
          goalSelection: testCase.selection,
          workoutIntroChoice: testCase.workoutIntroChoice,
          currentStepId: OnboardingStepId.targets,
          profile: _profileFor(
            explicitDirection,
            currentStepId: ProfileStepId.targetWeight,
            includeDirectionalTarget: testCase.expectWeightFollowUps,
          ),
          workout: _validWorkout(),
          targets: const TargetsOnboardingDraft(
            currentStepId: TargetStepId.goalPace,
            goalPaceKgPerWeek: 0.6,
          ),
        ),
      );

      expect(
        controller.state.bodyGoalFlowPlan.contains(ProfileStepId.targetWeight),
        testCase.expectWeightFollowUps,
        reason: '${testCase.name}: Target Weight Body Goal eligibility',
      );
      expect(
        controller.state.bodyGoalFlowPlan.contains(ProfileStepId.goalPace),
        testCase.expectWeightFollowUps,
        reason: '${testCase.name}: Goal Pace Body Goal eligibility',
      );
      expect(controller.state.targetsFlowPlan.contains(TargetStepId.goalPace), isFalse);
      expect(controller.state.targetsFlowPlan.steps, const [TargetStepId.nutritionTarget]);
      expect(controller.state.stepId, OnboardingStepId.bodyGoal);
      expect(
        controller.state.draft.profile.currentStepId,
        testCase.expectWeightFollowUps
            ? ProfileStepId.goalPace
            : ProfileStepId.currentWeight,
      );
      expect(controller.state.draft.targets.goalPaceKgPerWeek, 0.6);
      expect(
        controller.state.progressStepCount,
        testCase.expectedProgressCount,
        reason: '${testCase.name}: dynamic progress denominator',
      );
    }
  });

  test('training-only resume derives direction from stored target, not label', () {
    final controller = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      initialDraft: OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.getStronger,
        ),
        currentStepId: OnboardingStepId.bodyGoal,
        profile: _profileFor(
          null,
          currentStepId: ProfileStepId.goalPace,
          includeDirectionalTarget: true,
        ),
        workout: _validWorkout(),
      ),
    );

    expect(controller.state.weightGoalDirection, GoalWeightDirection.loss);
    expect(controller.state.draft.goalSelection.contains(GoalIntent.loseWeight), isFalse);
  });

  test('legacy Wellness cursors migrate losslessly across the mode matrix',
      () async {
    for (final testCase in cases) {
      final explicitDirection = policy.directionFor(
        mode: testCase.mode,
        selection: testCase.selection,
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: testCase.mode,
          goalSelection: testCase.selection,
          workoutIntroChoice: testCase.workoutIntroChoice,
          currentStepId: OnboardingStepId.targets,
          profile: _profileFor(
            explicitDirection,
            includeDirectionalTarget: testCase.expectWeightFollowUps,
          ),
          workout: _validWorkout(),
          targets: const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
            waterMl: 2500,
          ),
        ),
      );

      final wellnessIsActive = testCase.mode != AppMode.workout;
      expect(
        controller.state.stepId,
        wellnessIsActive
            ? OnboardingStepId.wellnessGoals
            : OnboardingStepId.workoutProfile,
      );
      expect(controller.state.draft.targets.waterMl, 2500);
      expect(controller.state.targetsFlowPlan.steps, const [TargetStepId.nutritionTarget]);

      if (!wellnessIsActive) continue;

      expect(controller.state.draft.targets.currentStepId, TargetStepId.waterTarget);
      controller.previous();
      expect(controller.state.draft.targets.currentStepId, TargetStepId.sleepTarget);
      await controller.next(onFinish: _completeImmediately);
      expect(controller.state.draft.targets.currentStepId, TargetStepId.waterTarget);
    }
  });
}

List<_AcceptanceCase> _acceptanceCases() {
  const trainingOnlyGoals = [
    GoalIntent.buildMuscle,
    GoalIntent.getStronger,
    GoalIntent.improveEndurance,
    GoalIntent.stayFit,
  ];

  const primaryLoss = GoalIntentSelection(primaryGoal: GoalIntent.loseWeight);

  return [
    const _AcceptanceCase(
      name: 'Nutrition Lose weight',
      mode: AppMode.nutrition,
      selection: primaryLoss,
      expectWeightFollowUps: true,
      expectedProgressCount: 20,
    ),
    const _AcceptanceCase(
      name: 'Nutrition Gain weight',
      mode: AppMode.nutrition,
      selection: GoalIntentSelection(primaryGoal: GoalIntent.gainWeight),
      expectWeightFollowUps: true,
      expectedProgressCount: 20,
    ),
    const _AcceptanceCase(
      name: 'Nutrition Maintain weight',
      mode: AppMode.nutrition,
      selection: GoalIntentSelection(primaryGoal: GoalIntent.maintainWeight),
      expectWeightFollowUps: false,
      expectedProgressCount: 18,
    ),
    const _AcceptanceCase(
      name: 'Workout Lose weight with training',
      mode: AppMode.workout,
      selection: GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
        supportingGoal: GoalIntent.getStronger,
      ),
      expectWeightFollowUps: true,
      expectedProgressCount: 21,
    ),
    const _AcceptanceCase(
      name: 'Workout Maintain plus training',
      mode: AppMode.workout,
      selection: GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
        supportingGoal: GoalIntent.buildMuscle,
      ),
      expectWeightFollowUps: false,
      expectedProgressCount: 19,
    ),
    for (final goal in trainingOnlyGoals)
      _AcceptanceCase(
        name: 'Workout ${goal.name}',
        mode: AppMode.workout,
        selection: GoalIntentSelection(primaryGoal: goal),
        expectWeightFollowUps: true,
        expectedProgressCount: 21,
      ),
    const _AcceptanceCase(
      name: 'Hybrid setup-now Lose weight',
      mode: AppMode.hybrid,
      selection: primaryLoss,
      workoutIntroChoice: WorkoutIntroChoice.setupNow,
      expectWeightFollowUps: true,
      expectedProgressCount: 29,
    ),
    const _AcceptanceCase(
      name: 'Hybrid setup-now Maintain plus training',
      mode: AppMode.hybrid,
      selection: GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
        supportingGoal: GoalIntent.buildMuscle,
      ),
      workoutIntroChoice: WorkoutIntroChoice.setupNow,
      expectWeightFollowUps: false,
      expectedProgressCount: 27,
    ),
    for (final goal in trainingOnlyGoals)
      _AcceptanceCase(
        name: 'Hybrid setup-now ${goal.name}',
        mode: AppMode.hybrid,
        selection: GoalIntentSelection(primaryGoal: goal),
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        expectWeightFollowUps: true,
        expectedProgressCount: 29,
      ),
    const _AcceptanceCase(
      name: 'Hybrid later Lose weight',
      mode: AppMode.hybrid,
      selection: primaryLoss,
      workoutIntroChoice: WorkoutIntroChoice.later,
      expectWeightFollowUps: true,
      expectedProgressCount: 21,
    ),
    for (final goal in trainingOnlyGoals)
      _AcceptanceCase(
        name: 'Hybrid later ${goal.name}',
        mode: AppMode.hybrid,
        selection: GoalIntentSelection(primaryGoal: goal),
        workoutIntroChoice: WorkoutIntroChoice.later,
        expectWeightFollowUps: true,
        expectedProgressCount: 21,
      ),
  ];
}

ProfileOnboardingDraft _profileFor(
  GoalWeightDirection? direction, {
  ProfileStepId currentStepId = ProfileStepId.healthConditions,
  bool includeDirectionalTarget = false,
}) {
  final storedDirection = direction ?? GoalWeightDirection.loss;
  final targetWeight = switch (storedDirection) {
    GoalWeightDirection.loss => 64.0,
    GoalWeightDirection.gain => 76.0,
  };

  return ProfileOnboardingDraft(
    currentStepId: currentStepId,
    name: 'Tio User',
    gender: ProfileGender.other,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: includeDirectionalTarget || direction != null ? targetWeight : null,
    targetWeightDirection:
        includeDirectionalTarget || direction != null ? storedDirection : null,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _validWorkout() {
  return const WorkoutOnboardingDraft(
    gymAccess: WorkoutGymAccess.gym,
    experienceLevel: WorkoutExperienceLevel.beginner,
    focusAreas: {WorkoutFocusArea.legs},
    trainingDays: {
      WorkoutTrainingDay.monday,
      WorkoutTrainingDay.wednesday,
    },
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.auto,
  );
}

Future<void> _completeImmediately(OnboardingDraft _) async {}

class _AcceptanceCase {
  const _AcceptanceCase({
    required this.name,
    required this.mode,
    required this.selection,
    required this.expectWeightFollowUps,
    required this.expectedProgressCount,
    this.workoutIntroChoice,
  });

  final String name;
  final AppMode mode;
  final GoalIntentSelection selection;
  final WorkoutIntroChoice? workoutIntroChoice;
  final bool expectWeightFollowUps;
  final int expectedProgressCount;
}

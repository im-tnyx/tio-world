import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const policy = WeightGoalFlowPolicy();
  final cases = _acceptanceCases();

  test('legacy Goal Pace cursors reconcile into Body Goal by mode and goal', () {
    for (final testCase in cases) {
      final direction = policy.directionFor(
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
            direction,
            currentStepId: ProfileStepId.targetWeight,
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
      expect(
        controller.state.targetsFlowPlan.contains(TargetStepId.goalPace),
        isFalse,
        reason: '${testCase.name}: active Targets must stay pace-free',
      );
      expect(
        controller.state.stepId,
        OnboardingStepId.bodyGoal,
        reason: '${testCase.name}: legacy Targets Goal Pace cursor migrates',
      );
      expect(
        controller.state.draft.profile.currentStepId,
        testCase.expectWeightFollowUps
            ? ProfileStepId.goalPace
            : ProfileStepId.currentWeight,
        reason: '${testCase.name}: Body Goal cursor follows active eligibility',
      );
      expect(
        controller.state.draft.targets.currentStepId,
        TargetStepId.bridge,
        reason: '${testCase.name}: obsolete Targets cursor is no longer active',
      );
      expect(
        controller.state.draft.targets.goalPaceKgPerWeek,
        0.6,
        reason: '${testCase.name}: Goal Pace value survives cursor migration',
      );
      expect(
        controller.state.progressStepCount,
        testCase.expectedProgressCount,
        reason: '${testCase.name}: dynamic progress denominator',
      );
    }
  });

  test('Targets Next and Back stay pace-free across the eligibility matrix', () async {
    for (final testCase in cases) {
      final direction = policy.directionFor(
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
          profile: _profileFor(direction),
          workout: _validWorkout(),
          targets: const TargetsOnboardingDraft(
            currentStepId: TargetStepId.waterTarget,
          ),
        ),
      );

      await controller.next(onFinish: _completeImmediately);

      expect(
        controller.state.draft.targets.currentStepId,
        TargetStepId.nutritionTarget,
        reason: '${testCase.name}: Water Target advances directly to Nutrition',
      );

      controller.previous();

      expect(
        controller.state.draft.targets.currentStepId,
        TargetStepId.waterTarget,
        reason: '${testCase.name}: Back returns to Water Target',
      );
    }
  });
}

List<_AcceptanceCase> _acceptanceCases() {
  const trainingOnlyGoals = [
    GoalIntent.buildMuscle,
    GoalIntent.getStronger,
    GoalIntent.improveEndurance,
    GoalIntent.stayFit,
    GoalIntent.recomposition,
  ];

  const primaryLoss = GoalIntentSelection(
    primaryGoal: GoalIntent.loseWeight,
  );
  const supportingLoss = GoalIntentSelection(
    primaryGoal: GoalIntent.getStronger,
    supportingGoal: GoalIntent.loseWeight,
  );

  return [
    const _AcceptanceCase(
      name: 'Nutrition Lose weight',
      mode: AppMode.nutrition,
      selection: primaryLoss,
      expectWeightFollowUps: true,
      expectedProgressCount: 17,
    ),
    const _AcceptanceCase(
      name: 'Nutrition Gain weight',
      mode: AppMode.nutrition,
      selection: GoalIntentSelection(primaryGoal: GoalIntent.gainWeight),
      expectWeightFollowUps: true,
      expectedProgressCount: 17,
    ),
    const _AcceptanceCase(
      name: 'Nutrition Maintain weight',
      mode: AppMode.nutrition,
      selection: GoalIntentSelection(primaryGoal: GoalIntent.maintainWeight),
      expectWeightFollowUps: false,
      expectedProgressCount: 15,
    ),
    const _AcceptanceCase(
      name: 'Nutrition Recomposition',
      mode: AppMode.nutrition,
      selection: GoalIntentSelection(primaryGoal: GoalIntent.recomposition),
      expectWeightFollowUps: false,
      expectedProgressCount: 15,
    ),
    const _AcceptanceCase(
      name: 'Workout Lose weight primary',
      mode: AppMode.workout,
      selection: primaryLoss,
      expectWeightFollowUps: true,
      expectedProgressCount: 25,
    ),
    const _AcceptanceCase(
      name: 'Workout Lose weight supporting',
      mode: AppMode.workout,
      selection: supportingLoss,
      expectWeightFollowUps: true,
      expectedProgressCount: 25,
    ),
    for (final goal in trainingOnlyGoals)
      _AcceptanceCase(
        name: 'Workout ${goal.name}',
        mode: AppMode.workout,
        selection: GoalIntentSelection(primaryGoal: goal),
        expectWeightFollowUps: false,
        expectedProgressCount: 23,
      ),
    const _AcceptanceCase(
      name: 'Hybrid setup-now Lose weight primary',
      mode: AppMode.hybrid,
      selection: primaryLoss,
      workoutIntroChoice: WorkoutIntroChoice.setupNow,
      expectWeightFollowUps: true,
      expectedProgressCount: 26,
    ),
    const _AcceptanceCase(
      name: 'Hybrid setup-now Lose weight supporting',
      mode: AppMode.hybrid,
      selection: supportingLoss,
      workoutIntroChoice: WorkoutIntroChoice.setupNow,
      expectWeightFollowUps: true,
      expectedProgressCount: 26,
    ),
    for (final goal in trainingOnlyGoals)
      _AcceptanceCase(
        name: 'Hybrid setup-now ${goal.name}',
        mode: AppMode.hybrid,
        selection: GoalIntentSelection(primaryGoal: goal),
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
        expectWeightFollowUps: false,
        expectedProgressCount: 24,
      ),
    const _AcceptanceCase(
      name: 'Hybrid later Lose weight primary',
      mode: AppMode.hybrid,
      selection: primaryLoss,
      workoutIntroChoice: WorkoutIntroChoice.later,
      expectWeightFollowUps: true,
      expectedProgressCount: 18,
    ),
    const _AcceptanceCase(
      name: 'Hybrid later Lose weight supporting',
      mode: AppMode.hybrid,
      selection: supportingLoss,
      workoutIntroChoice: WorkoutIntroChoice.later,
      expectWeightFollowUps: true,
      expectedProgressCount: 18,
    ),
    for (final goal in trainingOnlyGoals)
      _AcceptanceCase(
        name: 'Hybrid later ${goal.name}',
        mode: AppMode.hybrid,
        selection: GoalIntentSelection(primaryGoal: goal),
        workoutIntroChoice: WorkoutIntroChoice.later,
        expectWeightFollowUps: false,
        expectedProgressCount: 16,
      ),
  ];
}

ProfileOnboardingDraft _profileFor(
  GoalWeightDirection? direction, {
  ProfileStepId currentStepId = ProfileStepId.healthConditions,
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
    targetWeightKg: targetWeight,
    targetWeightDirection: storedDirection,
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

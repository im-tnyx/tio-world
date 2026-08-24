import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const bodyGoalPlanner = BuildBodyGoalFlowPlanUseCase();
  const targetsPlanner = BuildTargetsFlowPlanUseCase();

  BodyGoalFlowPlan bodyPlan({
    required AppMode mode,
    required GoalIntentSelection selection,
  }) =>
      bodyGoalPlanner(mode: mode, goalSelection: selection);

  test('nutrition Lose/Gain show paired follow-ups and Maintain hides both', () {
    const expected = <GoalIntent, bool>{
      GoalIntent.loseWeight: true,
      GoalIntent.gainWeight: true,
      GoalIntent.maintainWeight: false,
    };

    for (final entry in expected.entries) {
      final plan = bodyPlan(
        mode: AppMode.nutrition,
        selection: GoalIntentSelection(primaryGoal: entry.key),
      );
      expect(plan.contains(ProfileStepId.targetWeight), entry.value);
      expect(plan.contains(ProfileStepId.goalPace), entry.value);
    }
  });

  test('Workout/Hybrid training-only goals show paired Body follow-ups', () {
    const trainingGoals = [
      GoalIntent.buildMuscle,
      GoalIntent.getStronger,
      GoalIntent.improveEndurance,
      GoalIntent.stayFit,
    ];

    for (final mode in [AppMode.workout, AppMode.hybrid]) {
      for (final goal in trainingGoals) {
        final plan = bodyPlan(
          mode: mode,
          selection: GoalIntentSelection(primaryGoal: goal),
        );
        expect(plan.contains(ProfileStepId.targetWeight), isTrue,
            reason: '$goal should collect Target Weight in $mode');
        expect(plan.contains(ProfileStepId.goalPace), isTrue,
            reason: '$goal should collect Goal Pace in $mode');
      }
    }
  });

  test('explicit Maintain hides follow-ups even with training priorities', () {
    final plan = bodyPlan(
      mode: AppMode.hybrid,
      selection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
        supportingGoal: GoalIntent.buildMuscle,
        tertiaryGoal: GoalIntent.getStronger,
      ),
    );

    expect(plan.contains(ProfileStepId.targetWeight), isFalse);
    expect(plan.contains(ProfileStepId.goalPace), isFalse);
  });

  test('Body Lose/Gain plus training keep paired follow-ups', () {
    for (final bodyGoal in [GoalIntent.loseWeight, GoalIntent.gainWeight]) {
      final plan = bodyPlan(
        mode: AppMode.workout,
        selection: GoalIntentSelection(
          primaryGoal: bodyGoal,
          supportingGoal: GoalIntent.buildMuscle,
          tertiaryGoal: GoalIntent.improveEndurance,
        ),
      );
      expect(plan.contains(ProfileStepId.targetWeight), isTrue);
      expect(plan.contains(ProfileStepId.goalPace), isTrue);
    }
  });

  test('active Targets plan never contains Goal Pace for any mode', () {
    for (final mode in AppMode.values) {
      final plan = targetsPlanner(
        mode: mode,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
      );
      expect(plan.contains(TargetStepId.goalPace), isFalse);
    }
  });

  test('Body Goal reconcile removes Target Weight and Goal Pace together', () {
    final previousPlan = bodyGoalPlanner(
      mode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
    );
    final nextPlan = bodyGoalPlanner(
      mode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
      ),
    );

    for (final child in [ProfileStepId.targetWeight, ProfileStepId.goalPace]) {
      expect(
        bodyGoalPlanner.reconcileCurrentStep(
          currentStepId: child,
          previousPlan: previousPlan,
          nextPlan: nextPlan,
        ),
        ProfileStepId.currentWeight,
      );
    }
  });

  test('generic legacy Targets fallback resolves to active Nutrition Target', () {
    const legacyPlan = TargetsFlowPlan(steps: TargetsFlowPlan.legacyOrderedSteps);
    final activePlan = targetsPlanner(
      mode: AppMode.hybrid,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
    );

    expect(
      targetsPlanner.reconcileCurrentStep(
        currentStepId: TargetStepId.goalPace,
        previousPlan: legacyPlan,
        nextPlan: activePlan,
      ),
      TargetStepId.nutritionTarget,
    );
  });
}

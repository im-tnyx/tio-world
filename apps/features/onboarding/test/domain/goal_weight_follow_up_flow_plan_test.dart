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

  test('nutrition Target Weight and Goal Pace share the approved matrix', () {
    const expected = <GoalIntent, bool>{
      GoalIntent.loseWeight: true,
      GoalIntent.gainWeight: true,
      GoalIntent.maintainWeight: false,
      GoalIntent.recomposition: false,
    };

    for (final entry in expected.entries) {
      final selection = GoalIntentSelection(primaryGoal: entry.key);
      final plan = bodyPlan(mode: AppMode.nutrition, selection: selection);

      expect(
        plan.contains(ProfileStepId.targetWeight),
        entry.value,
        reason: 'Target Weight eligibility for ${entry.key}',
      );
      expect(
        plan.contains(ProfileStepId.goalPace),
        entry.value,
        reason: 'Goal Pace eligibility for ${entry.key}',
      );
      expect(
        plan.contains(ProfileStepId.targetWeight),
        plan.contains(ProfileStepId.goalPace),
        reason: 'Body follow-ups must never diverge for ${entry.key}',
      );
    }
  });

  test('workout and hybrid activate both follow-ups only for selected loss', () {
    const trainingOnly = [
      GoalIntent.buildMuscle,
      GoalIntent.getStronger,
      GoalIntent.improveEndurance,
      GoalIntent.stayFit,
      GoalIntent.recomposition,
    ];

    for (final mode in [AppMode.workout, AppMode.hybrid]) {
      const primaryLoss = GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      );
      const supportingLoss = GoalIntentSelection(
        primaryGoal: GoalIntent.getStronger,
        supportingGoal: GoalIntent.loseWeight,
      );

      for (final selection in [primaryLoss, supportingLoss]) {
        final plan = bodyPlan(mode: mode, selection: selection);
        expect(plan.contains(ProfileStepId.targetWeight), isTrue);
        expect(plan.contains(ProfileStepId.goalPace), isTrue);
      }

      for (final goal in trainingOnly) {
        final selection = GoalIntentSelection(primaryGoal: goal);
        final plan = bodyPlan(mode: mode, selection: selection);
        expect(
          plan.contains(ProfileStepId.targetWeight),
          isFalse,
          reason: '$goal must not activate Target Weight in $mode',
        );
        expect(
          plan.contains(ProfileStepId.goalPace),
          isFalse,
          reason: '$goal must not activate Goal Pace in $mode',
        );
      }
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

    expect(
      bodyGoalPlanner.reconcileCurrentStep(
        currentStepId: ProfileStepId.targetWeight,
        previousPlan: previousPlan,
        nextPlan: nextPlan,
      ),
      ProfileStepId.currentWeight,
    );
    expect(
      bodyGoalPlanner.reconcileCurrentStep(
        currentStepId: ProfileStepId.goalPace,
        previousPlan: previousPlan,
        nextPlan: nextPlan,
      ),
      ProfileStepId.currentWeight,
    );
  });

  test('generic legacy Targets fallback resolves to active Nutrition Target', () {
    const legacyPlan = TargetsFlowPlan(
      steps: TargetsFlowPlan.legacyOrderedSteps,
    );
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

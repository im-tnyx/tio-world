import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const profilePlanner = BuildProfileFlowPlanUseCase();
  const targetsPlanner = BuildTargetsFlowPlanUseCase();

  bool profileCollects({
    required AppMode mode,
    required GoalIntentSelection selection,
  }) =>
      profilePlanner(mode: mode, goalSelection: selection)
          .contains(ProfileStepId.targetWeight);

  bool targetsCollects({
    required AppMode mode,
    required GoalIntentSelection selection,
  }) =>
      targetsPlanner(mode: mode, goalSelection: selection)
          .contains(TargetStepId.goalPace);

  test('nutrition flow follows the approved weight-change matrix', () {
    const expected = <GoalIntent, bool>{
      GoalIntent.loseWeight: true,
      GoalIntent.gainWeight: true,
      GoalIntent.maintainWeight: false,
      GoalIntent.recomposition: false,
    };

    for (final entry in expected.entries) {
      final selection = GoalIntentSelection(primaryGoal: entry.key);
      expect(
        profileCollects(mode: AppMode.nutrition, selection: selection),
        entry.value,
        reason: 'Target Weight eligibility for ${entry.key}',
      );
      expect(
        targetsCollects(mode: AppMode.nutrition, selection: selection),
        entry.value,
        reason: 'Goal Pace eligibility for ${entry.key}',
      );
    }
  });

  test('workout and hybrid collect follow-ups only when lose weight is selected', () {
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
        expect(profileCollects(mode: mode, selection: selection), isTrue);
        expect(targetsCollects(mode: mode, selection: selection), isTrue);
      }

      for (final goal in trainingOnly) {
        final selection = GoalIntentSelection(primaryGoal: goal);
        expect(
          profileCollects(mode: mode, selection: selection),
          isFalse,
          reason: '$goal must not activate Target Weight in $mode',
        );
        expect(
          targetsCollects(mode: mode, selection: selection),
          isFalse,
          reason: '$goal must not activate Goal Pace in $mode',
        );
      }
    }
  });

  test('reconcile moves an ineligible Target Weight step to Current Weight', () {
    final previousPlan = profilePlanner(
      mode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
    );
    final nextPlan = profilePlanner(
      mode: AppMode.nutrition,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
      ),
    );

    expect(
      profilePlanner.reconcileCurrentStep(
        currentStepId: ProfileStepId.targetWeight,
        previousPlan: previousPlan,
        nextPlan: nextPlan,
      ),
      ProfileStepId.currentWeight,
    );
  });

  test('reconcile moves an ineligible Goal Pace step to Water Target', () {
    final previousPlan = targetsPlanner(
      mode: AppMode.hybrid,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
    );
    final nextPlan = targetsPlanner(
      mode: AppMode.hybrid,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.getStronger,
      ),
    );

    expect(
      targetsPlanner.reconcileCurrentStep(
        currentStepId: TargetStepId.goalPace,
        previousPlan: previousPlan,
        nextPlan: nextPlan,
      ),
      TargetStepId.waterTarget,
    );
  });
}

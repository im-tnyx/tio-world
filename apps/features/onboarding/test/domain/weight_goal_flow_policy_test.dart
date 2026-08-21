import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const policy = WeightGoalFlowPolicy();

  test('nutrition exposes explicit loss and gain directions only', () {
    expect(
      policy.directionFor(
        mode: AppMode.nutrition,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
      ),
      GoalWeightDirection.loss,
    );
    expect(
      policy.directionFor(
        mode: AppMode.nutrition,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.gainWeight,
        ),
      ),
      GoalWeightDirection.gain,
    );

    for (final goal in [GoalIntent.maintainWeight, GoalIntent.recomposition]) {
      expect(
        policy.directionFor(
          mode: AppMode.nutrition,
          selection: GoalIntentSelection(primaryGoal: goal),
        ),
        isNull,
      );
    }
  });

  test('workout and hybrid use lose weight from either selected position', () {
    for (final mode in [AppMode.workout, AppMode.hybrid]) {
      expect(
        policy.directionFor(
          mode: mode,
          selection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
          ),
        ),
        GoalWeightDirection.loss,
      );
      expect(
        policy.directionFor(
          mode: mode,
          selection: const GoalIntentSelection(
            primaryGoal: GoalIntent.getStronger,
            supportingGoal: GoalIntent.loseWeight,
          ),
        ),
        GoalWeightDirection.loss,
      );
      expect(
        policy.directionFor(
          mode: mode,
          selection: const GoalIntentSelection(
            primaryGoal: GoalIntent.buildMuscle,
            supportingGoal: GoalIntent.getStronger,
          ),
        ),
        isNull,
      );
    }
  });

  test('target weight and goal pace share the same eligibility', () {
    const selection = GoalIntentSelection(primaryGoal: GoalIntent.loseWeight);
    expect(
      policy.requiresTargetWeight(
        mode: AppMode.hybrid,
        selection: selection,
      ),
      isTrue,
    );
    expect(
      policy.requiresGoalPace(
        mode: AppMode.hybrid,
        selection: selection,
      ),
      isTrue,
    );
  });
}

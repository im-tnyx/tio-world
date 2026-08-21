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
    }
  });

  test('training-only goals never invent body-weight direction', () {
    const trainingOnlyGoals = [
      GoalIntent.buildMuscle,
      GoalIntent.getStronger,
      GoalIntent.improveEndurance,
      GoalIntent.stayFit,
      GoalIntent.recomposition,
    ];

    for (final mode in [AppMode.workout, AppMode.hybrid]) {
      for (final goal in trainingOnlyGoals) {
        expect(
          policy.directionFor(
            mode: mode,
            selection: GoalIntentSelection(primaryGoal: goal),
          ),
          isNull,
          reason: '$goal must not imply weight change in $mode',
        );
      }

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

  test('build muscle is never treated as gain weight', () {
    for (final mode in [AppMode.workout, AppMode.hybrid]) {
      expect(
        policy.directionFor(
          mode: mode,
          selection: const GoalIntentSelection(
            primaryGoal: GoalIntent.buildMuscle,
          ),
        ),
        isNot(GoalWeightDirection.gain),
      );
    }
  });

  test('target weight and goal pace share the same eligibility', () {
    const weightSelection = GoalIntentSelection(
      primaryGoal: GoalIntent.loseWeight,
    );
    const nonWeightSelection = GoalIntentSelection(
      primaryGoal: GoalIntent.getStronger,
    );

    expect(
      policy.requiresTargetWeight(
        mode: AppMode.hybrid,
        selection: weightSelection,
      ),
      isTrue,
    );
    expect(
      policy.requiresGoalPace(
        mode: AppMode.hybrid,
        selection: weightSelection,
      ),
      isTrue,
    );
    expect(
      policy.requiresTargetWeight(
        mode: AppMode.hybrid,
        selection: nonWeightSelection,
      ),
      isFalse,
    );
    expect(
      policy.requiresGoalPace(
        mode: AppMode.hybrid,
        selection: nonWeightSelection,
      ),
      isFalse,
    );
  });

  test('missing mode never activates weight follow-ups', () {
    const selection = GoalIntentSelection(primaryGoal: GoalIntent.loseWeight);

    expect(policy.directionFor(mode: null, selection: selection), isNull);
    expect(
      policy.shouldCollectTargetWeight(mode: null, selection: selection),
      isFalse,
    );
    expect(
      policy.shouldCollectGoalPace(mode: null, selection: selection),
      isFalse,
    );
  });
}

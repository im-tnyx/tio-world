import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const policy = WeightGoalFlowPolicy();

  test('explicit Lose/Gain cards establish direction in every active mode', () {
    for (final mode in AppMode.values) {
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
            primaryGoal: GoalIntent.gainWeight,
          ),
        ),
        GoalWeightDirection.gain,
      );
    }
  });

  test('training labels never invent body-weight direction', () {
    for (final goal in [
      GoalIntent.buildMuscle,
      GoalIntent.getStronger,
      GoalIntent.improveEndurance,
      GoalIntent.stayFit,
    ]) {
      expect(
        policy.directionFor(
          mode: AppMode.workout,
          selection: GoalIntentSelection(primaryGoal: goal),
        ),
        isNull,
      );
    }
  });

  test('training-only path derives loss/gain only from actual Target Weight', () {
    const selection = GoalIntentSelection(
      primaryGoal: GoalIntent.buildMuscle,
      supportingGoal: GoalIntent.getStronger,
    );

    expect(
      policy.effectiveDirectionFor(
        mode: AppMode.workout,
        selection: selection,
        currentWeightKg: 80,
        targetWeightKg: 75,
      ),
      GoalWeightDirection.loss,
    );
    expect(
      policy.effectiveDirectionFor(
        mode: AppMode.workout,
        selection: selection,
        currentWeightKg: 80,
        targetWeightKg: 85,
      ),
      GoalWeightDirection.gain,
    );
    expect(
      policy.effectiveDirectionFor(
        mode: AppMode.workout,
        selection: selection,
        currentWeightKg: 80,
        targetWeightKg: 80,
      ),
      isNull,
    );
  });

  test('training-only goals collect paired Target Weight and Goal Pace', () {
    const selection = GoalIntentSelection(
      primaryGoal: GoalIntent.getStronger,
    );

    expect(
      policy.requiresTargetWeight(mode: AppMode.hybrid, selection: selection),
      isTrue,
    );
    expect(
      policy.requiresGoalPace(mode: AppMode.hybrid, selection: selection),
      isTrue,
    );
  });

  test('explicit Maintain stays non-directional and hides paired follow-ups', () {
    const selection = GoalIntentSelection(
      primaryGoal: GoalIntent.maintainWeight,
      supportingGoal: GoalIntent.buildMuscle,
    );

    expect(
      policy.effectiveDirectionFor(
        mode: AppMode.hybrid,
        selection: selection,
        currentWeightKg: 80,
        targetWeightKg: 75,
      ),
      isNull,
    );
    expect(
      policy.shouldCollectTargetWeight(
        mode: AppMode.hybrid,
        selection: selection,
      ),
      isFalse,
    );
    expect(
      policy.shouldCollectGoalPace(
        mode: AppMode.hybrid,
        selection: selection,
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

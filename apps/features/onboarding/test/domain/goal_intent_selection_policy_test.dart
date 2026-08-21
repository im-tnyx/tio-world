import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const policy = GoalIntentSelectionPolicy();

  test('nutrition exposes body-direction intents and no supporting goal', () {
    expect(
      policy.optionsFor(AppMode.nutrition),
      const [
        GoalIntent.loseWeight,
        GoalIntent.gainWeight,
        GoalIntent.maintainWeight,
        GoalIntent.recomposition,
      ],
    );
    expect(policy.allowsSupportingGoal(AppMode.nutrition), isFalse);
    expect(
      policy.validate(
        mode: AppMode.nutrition,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.getStronger,
        ),
      ),
      isNotNull,
    );
  });

  test('workout and hybrid expose the approved six-card set', () {
    const expected = [
      GoalIntent.loseWeight,
      GoalIntent.buildMuscle,
      GoalIntent.getStronger,
      GoalIntent.improveEndurance,
      GoalIntent.stayFit,
      GoalIntent.recomposition,
    ];

    expect(policy.optionsFor(AppMode.workout), expected);
    expect(policy.optionsFor(AppMode.hybrid), expected);
  });

  test('compatible supporting pairs validate without changing ownership', () {
    expect(
      policy.validate(
        mode: AppMode.workout,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.getStronger,
        ),
      ),
      isNull,
    );
    expect(
      policy.validate(
        mode: AppMode.hybrid,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.improveEndurance,
        ),
      ),
      isNull,
    );
  });

  test('redundant or contradictory supporting pairs are rejected', () {
    expect(
      policy.validate(
        mode: AppMode.workout,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.stayFit,
        ),
      ),
      'Choose a compatible supporting goal.',
    );
    expect(
      policy.validate(
        mode: AppMode.hybrid,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.recomposition,
          supportingGoal: GoalIntent.stayFit,
        ),
      ),
      'Choose a compatible supporting goal.',
    );
  });
}

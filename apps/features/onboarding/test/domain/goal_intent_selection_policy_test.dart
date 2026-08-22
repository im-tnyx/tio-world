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

  test('nutrition tap always replaces the single primary goal', () {
    final next = policy.applyTap(
      mode: AppMode.nutrition,
      current: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
      tappedGoal: GoalIntent.gainWeight,
    );

    expect(
      next,
      const GoalIntentSelection(primaryGoal: GoalIntent.gainWeight),
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

  test('compatible second tap becomes supporting and third replaces it', () {
    final primary = policy.applyTap(
      mode: AppMode.workout,
      current: const GoalIntentSelection(),
      tappedGoal: GoalIntent.buildMuscle,
    );
    final withSupporting = policy.applyTap(
      mode: AppMode.workout,
      current: primary,
      tappedGoal: GoalIntent.getStronger,
    );
    final replacedSupporting = policy.applyTap(
      mode: AppMode.workout,
      current: withSupporting,
      tappedGoal: GoalIntent.recomposition,
    );

    expect(
      withSupporting,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.buildMuscle,
        supportingGoal: GoalIntent.getStronger,
      ),
    );
    expect(
      replacedSupporting,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.buildMuscle,
        supportingGoal: GoalIntent.recomposition,
      ),
    );
  });

  test('incompatible new tap starts a new primary selection', () {
    final next = policy.applyTap(
      mode: AppMode.hybrid,
      current: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
        supportingGoal: GoalIntent.improveEndurance,
      ),
      tappedGoal: GoalIntent.stayFit,
    );

    expect(
      next,
      const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
    );
  });

  test('mode reconciliation drops invalid supporting or promotes visible one', () {
    expect(
      policy.reconcileForMode(
        mode: AppMode.nutrition,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.improveEndurance,
        ),
      ),
      const GoalIntentSelection(primaryGoal: GoalIntent.loseWeight),
    );

    expect(
      policy.reconcileForMode(
        mode: AppMode.nutrition,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.getStronger,
          supportingGoal: GoalIntent.loseWeight,
        ),
      ),
      const GoalIntentSelection(primaryGoal: GoalIntent.loseWeight),
    );
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

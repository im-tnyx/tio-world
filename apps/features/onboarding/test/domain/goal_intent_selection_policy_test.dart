import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const policy = GoalIntentSelectionPolicy();

  test('nutrition exposes exactly three weight-state goals', () {
    expect(
      policy.optionsFor(AppMode.nutrition),
      const [
        GoalIntent.loseWeight,
        GoalIntent.gainWeight,
        GoalIntent.maintainWeight,
      ],
    );
    expect(policy.allowsSupportingGoal(AppMode.nutrition), isFalse);
    expect(
      policy.optionsFor(AppMode.nutrition),
      isNot(contains(GoalIntent.recomposition)),
    );
  });

  test('nutrition tap always replaces the single weight goal', () {
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

  test('workout and hybrid expose the approved five-card outcome set', () {
    const expected = [
      GoalIntent.loseWeight,
      GoalIntent.buildMuscle,
      GoalIntent.getStronger,
      GoalIntent.improveEndurance,
      GoalIntent.stayFit,
    ];

    expect(policy.optionsFor(AppMode.workout), expected);
    expect(policy.optionsFor(AppMode.hybrid), expected);
    expect(expected, isNot(contains(GoalIntent.gainWeight)));
    expect(expected, isNot(contains(GoalIntent.maintainWeight)));
    expect(expected, isNot(contains(GoalIntent.recomposition)));
  });

  test('hidden Workout and Hybrid weight cards cannot be selected', () {
    const current = GoalIntentSelection(
      primaryGoal: GoalIntent.buildMuscle,
    );

    expect(
      policy.applyTap(
        mode: AppMode.workout,
        current: current,
        tappedGoal: GoalIntent.gainWeight,
      ),
      current,
    );
    expect(
      policy.applyTap(
        mode: AppMode.hybrid,
        current: current,
        tappedGoal: GoalIntent.maintainWeight,
      ),
      current,
    );
  });

  test('Fat Loss compatibility intent and two training goals coexist', () {
    var selection = policy.applyTap(
      mode: AppMode.workout,
      current: const GoalIntentSelection(),
      tappedGoal: GoalIntent.loseWeight,
    );
    selection = policy.applyTap(
      mode: AppMode.workout,
      current: selection,
      tappedGoal: GoalIntent.buildMuscle,
    );
    selection = policy.applyTap(
      mode: AppMode.workout,
      current: selection,
      tappedGoal: GoalIntent.getStronger,
    );

    expect(
      selection,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
        supportingGoal: GoalIntent.buildMuscle,
        tertiaryGoal: GoalIntent.getStronger,
      ),
    );
    expect(
      policy.validate(mode: AppMode.workout, selection: selection),
      isNull,
    );
  });

  test('third training tap preserves first priority and replaces supporting', () {
    final next = policy.applyTap(
      mode: AppMode.workout,
      current: const GoalIntentSelection(
        primaryGoal: GoalIntent.buildMuscle,
        supportingGoal: GoalIntent.getStronger,
      ),
      tappedGoal: GoalIntent.improveEndurance,
    );

    expect(
      next,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.buildMuscle,
        supportingGoal: GoalIntent.improveEndurance,
      ),
    );
  });

  test('tapping selected training goal removes only that training goal', () {
    final next = policy.applyTap(
      mode: AppMode.hybrid,
      current: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
        supportingGoal: GoalIntent.buildMuscle,
        tertiaryGoal: GoalIntent.getStronger,
      ),
      tappedGoal: GoalIntent.buildMuscle,
    );

    expect(
      next,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
        supportingGoal: GoalIntent.getStronger,
      ),
    );
  });

  test('mode reconciliation keeps visible Body goal and drops training in nutrition', () {
    expect(
      policy.reconcileForMode(
        mode: AppMode.nutrition,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.buildMuscle,
          tertiaryGoal: GoalIntent.getStronger,
        ),
      ),
      const GoalIntentSelection(primaryGoal: GoalIntent.loseWeight),
    );
  });

  test('Workout and Hybrid reconcile hidden historical weight goals away', () {
    expect(
      policy.reconcileForMode(
        mode: AppMode.workout,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.gainWeight,
          supportingGoal: GoalIntent.buildMuscle,
          tertiaryGoal: GoalIntent.getStronger,
        ),
      ),
      const GoalIntentSelection(
        primaryGoal: GoalIntent.buildMuscle,
        supportingGoal: GoalIntent.getStronger,
      ),
    );
    expect(
      policy.reconcileForMode(
        mode: AppMode.hybrid,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.maintainWeight,
          supportingGoal: GoalIntent.improveEndurance,
        ),
      ),
      const GoalIntentSelection(
        primaryGoal: GoalIntent.improveEndurance,
      ),
    );
  });

  test('legacy recomposition is decode-compatible but not active after reconcile', () {
    expect(
      policy.reconcileForMode(
        mode: AppMode.hybrid,
        selection: const GoalIntentSelection(
          primaryGoal: GoalIntent.recomposition,
          supportingGoal: GoalIntent.buildMuscle,
        ),
      ),
      const GoalIntentSelection(primaryGoal: GoalIntent.buildMuscle),
    );
  });

  test('empty selection is invalid but training-only workout selection is valid', () {
    expect(
      policy.validate(
        mode: AppMode.workout,
        selection: const GoalIntentSelection(),
      ),
      'Choose at least one goal.',
    );
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
  });
}

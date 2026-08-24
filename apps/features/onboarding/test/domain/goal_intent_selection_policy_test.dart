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
    expect(policy.optionsFor(AppMode.nutrition), isNot(contains(GoalIntent.recomposition)));
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

  test('workout and hybrid expose the approved seven-card set', () {
    const expected = [
      GoalIntent.loseWeight,
      GoalIntent.gainWeight,
      GoalIntent.maintainWeight,
      GoalIntent.buildMuscle,
      GoalIntent.getStronger,
      GoalIntent.improveEndurance,
      GoalIntent.stayFit,
    ];

    expect(policy.optionsFor(AppMode.workout), expected);
    expect(policy.optionsFor(AppMode.hybrid), expected);
    expect(expected, isNot(contains(GoalIntent.recomposition)));
  });

  test('one Body goal and two training goals coexist in three slots', () {
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
    expect(policy.validate(mode: AppMode.workout, selection: selection), isNull);
  });

  test('changing Body goal preserves both training selections', () {
    final next = policy.applyTap(
      mode: AppMode.hybrid,
      current: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
        supportingGoal: GoalIntent.buildMuscle,
        tertiaryGoal: GoalIntent.improveEndurance,
      ),
      tappedGoal: GoalIntent.gainWeight,
    );

    expect(
      next,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.gainWeight,
        supportingGoal: GoalIntent.buildMuscle,
        tertiaryGoal: GoalIntent.improveEndurance,
      ),
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
        primaryGoal: GoalIntent.maintainWeight,
        supportingGoal: GoalIntent.buildMuscle,
        tertiaryGoal: GoalIntent.getStronger,
      ),
      tappedGoal: GoalIntent.buildMuscle,
    );

    expect(
      next,
      const GoalIntentSelection(
        primaryGoal: GoalIntent.maintainWeight,
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

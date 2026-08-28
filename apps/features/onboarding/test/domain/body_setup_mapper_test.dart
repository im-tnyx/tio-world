import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_progress/progress.dart' as body_owner;
import 'package:tio_shared/shared.dart';

void main() {
  const mapper = BodySetupMapper();

  test('Nutrition Lose maps primary Body Goal, matching target and pace', () {
    final result = mapper.map(
      OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
        ),
        profile: _profile(
          currentWeightKg: 80,
          targetWeightKg: 76,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
        targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
      ),
    );

    expect(result.currentWeightKg, 80);
    expect(result.activeGoal?.goalType, body_owner.BodyGoalType.loseWeight);
    expect(result.activeGoal?.targetWeightKg, 76);
    expect(result.activeGoal?.weeklyWeightChangeKg, 0.5);
    expect(result.activeGoal?.intentRank, 1);
  });

  test('Nutrition Gain maps gain Body Goal with matching target and pace', () {
    final result = mapper.map(
      OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.gainWeight,
        ),
        profile: _profile(
          currentWeightKg: 80,
          targetWeightKg: 84,
          targetWeightDirection: GoalWeightDirection.gain,
        ),
        targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.3),
      ),
    );

    expect(result.activeGoal?.goalType, body_owner.BodyGoalType.gainWeight);
    expect(result.activeGoal?.targetWeightKg, 84);
    expect(result.activeGoal?.weeklyWeightChangeKg, 0.3);
    expect(result.activeGoal?.intentRank, 1);
  });

  for (final intent in [GoalIntent.maintainWeight, GoalIntent.recomposition]) {
    test('$intent maps Body Goal but never dormant Target Weight or pace', () {
      final result = mapper.map(
        OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: GoalIntentSelection(primaryGoal: intent),
          profile: _profile(
            currentWeightKg: 80,
            targetWeightKg: 76,
            targetWeightDirection: GoalWeightDirection.loss,
          ),
          targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.5),
        ),
      );

      expect(result.activeGoal, isNotNull);
      expect(result.activeGoal?.targetWeightKg, isNull);
      expect(result.activeGoal?.weeklyWeightChangeKg, isNull);
      expect(result.activeGoal?.intentRank, 1);
    });
  }

  test('training-only Workout goal does not fabricate Body Goal', () {
    final result = mapper.map(
      OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.getStronger,
        ),
        profile: _profile(currentWeightKg: 80),
      ),
    );

    expect(result.currentWeightKg, 80);
    expect(result.activeGoal, isNull);
  });

  test('Lose supporting goal maps Body Goal with rank 2', () {
    final result = mapper.map(
      OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.getStronger,
          supportingGoal: GoalIntent.loseWeight,
        ),
        profile: _profile(
          currentWeightKg: 80,
          targetWeightKg: 76,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
        targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.4),
      ),
    );

    expect(result.activeGoal?.goalType, body_owner.BodyGoalType.loseWeight);
    expect(result.activeGoal?.intentRank, 2);
    expect(result.activeGoal?.targetWeightKg, 76);
    expect(result.activeGoal?.weeklyWeightChangeKg, 0.4);
  });

  test('Recomposition supporting goal maps Body rank 2 without follow-ups', () {
    final result = mapper.map(
      OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.buildMuscle,
          supportingGoal: GoalIntent.recomposition,
        ),
        profile: _profile(
          currentWeightKg: 80,
          targetWeightKg: 76,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
        targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.4),
      ),
    );

    expect(result.activeGoal?.goalType, body_owner.BodyGoalType.recomposition);
    expect(result.activeGoal?.intentRank, 2);
    expect(result.activeGoal?.targetWeightKg, isNull);
    expect(result.activeGoal?.weeklyWeightChangeKg, isNull);
  });

  test('opposite stored target direction is not consumed by active Body Goal', () {
    final result = mapper.map(
      OnboardingDraft(
        selectedMode: AppMode.nutrition,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.gainWeight,
        ),
        profile: _profile(
          currentWeightKg: 80,
          targetWeightKg: 76,
          targetWeightDirection: GoalWeightDirection.loss,
        ),
        targets: const TargetsOnboardingDraft(goalPaceKgPerWeek: 0.3),
      ),
    );

    expect(result.activeGoal?.goalType, body_owner.BodyGoalType.gainWeight);
    expect(result.activeGoal?.targetWeightKg, isNull);
    expect(result.activeGoal?.weeklyWeightChangeKg, 0.3);
  });

  test('missing current weight stays null instead of fabricating default', () {
    final result = mapper.map(
      OnboardingDraft(
        selectedMode: AppMode.workout,
        goalSelection: const GoalIntentSelection(
          primaryGoal: GoalIntent.stayFit,
        ),
      ),
    );

    expect(result.currentWeightKg, isNull);
    expect(result.activeGoal, isNull);
  });
}

ProfileOnboardingDraft _profile({
  double? currentWeightKg,
  double? targetWeightKg,
  GoalWeightDirection? targetWeightDirection,
}) {
  return ProfileOnboardingDraft(
    currentWeightKg: currentWeightKg,
    targetWeightKg: targetWeightKg,
    targetWeightDirection: targetWeightDirection,
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const mapper = OnboardingDraftSnapshotDtoMapper();

  test('tertiary goal round-trips additively inside existing draft schema', () {
    final snapshot = OnboardingDraftSnapshot(
      draft: const OnboardingDraft(
        goalSelection: GoalIntentSelection(
          primaryGoal: GoalIntent.loseWeight,
          supportingGoal: GoalIntent.buildMuscle,
          tertiaryGoal: GoalIntent.getStronger,
        ),
      ),
      updatedAt: DateTime.utc(2026, 8, 24),
    );

    final json = mapper.toJson(snapshot);
    expect(
      json['goal_selection'],
      {
        'primary_goal': 'loseWeight',
        'supporting_goal': 'buildMuscle',
        'tertiary_goal': 'getStronger',
      },
    );

    expect(mapper.fromJson(json).draft.goalSelection, snapshot.draft.goalSelection);
  });

  test('two-slot legacy payload stays byte-shape compatible when tertiary is null', () {
    final json = mapper.toJson(
      OnboardingDraftSnapshot(
        draft: const OnboardingDraft(
          goalSelection: GoalIntentSelection(
            primaryGoal: GoalIntent.buildMuscle,
            supportingGoal: GoalIntent.getStronger,
          ),
        ),
        updatedAt: DateTime.utc(2026, 8, 24),
      ),
    );

    expect(
      json['goal_selection'],
      {
        'primary_goal': 'buildMuscle',
        'supporting_goal': 'getStronger',
      },
    );
  });
}

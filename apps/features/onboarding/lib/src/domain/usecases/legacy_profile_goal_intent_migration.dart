import 'package:tio_shared/shared.dart';

import '../models/models.dart';
import 'goal_intent_selection_policy.dart';

/// Best-effort migration from the legacy mixed ProfileGoal draft field.
///
/// Only meaning-preserving mappings are allowed. Unsupported legacy intents are
/// dropped rather than guessed, and the result is reconciled against App Mode.
class LegacyProfileGoalIntentMigration {
  const LegacyProfileGoalIntentMigration({
    this.policy = const GoalIntentSelectionPolicy(),
  });

  final GoalIntentSelectionPolicy policy;

  GoalIntentSelection call({
    required AppMode? mode,
    required Set<ProfileGoal> legacyGoals,
  }) {
    if (mode == null || legacyGoals.isEmpty) {
      return const GoalIntentSelection();
    }

    final primary = _legacyPrimary(legacyGoals);
    final supporting = legacyGoals.contains(ProfileGoal.boostStrength)
        ? GoalIntent.getStronger
        : null;

    return policy.reconcileForMode(
      mode: mode,
      selection: GoalIntentSelection(
        primaryGoal: primary,
        supportingGoal: supporting,
      ),
    );
  }

  GoalIntent? _legacyPrimary(Set<ProfileGoal> goals) {
    if (goals.contains(ProfileGoal.loseWeight)) {
      return GoalIntent.loseWeight;
    }
    if (goals.contains(ProfileGoal.buildMuscle)) {
      return GoalIntent.buildMuscle;
    }
    if (goals.contains(ProfileGoal.keepFit)) {
      return GoalIntent.stayFit;
    }
    return null;
  }
}

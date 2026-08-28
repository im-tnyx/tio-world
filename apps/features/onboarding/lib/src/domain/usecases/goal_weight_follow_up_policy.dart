import 'package:tio_shared/shared.dart';

import '../models/models.dart';

/// Single source of truth for body-weight follow-up semantics in onboarding.
///
/// Explicit Lose/Gain Goal cards establish direction immediately. Training-only
/// paths may still collect Target Weight + Goal Pace, but their direction comes
/// only from the user's actual target-vs-current answer. Training labels, BMI,
/// calories and defaults never invent Body direction.
class GoalWeightFollowUpPolicy {
  const GoalWeightFollowUpPolicy();

  GoalWeightDirection? directionFor({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) {
    if (mode == null) return null;
    if (selection.contains(GoalIntent.loseWeight)) {
      return GoalWeightDirection.loss;
    }
    if (selection.contains(GoalIntent.gainWeight)) {
      return GoalWeightDirection.gain;
    }
    return null;
  }

  GoalWeightDirection? directionFromTarget({
    required double? currentWeightKg,
    required double? targetWeightKg,
  }) {
    if (currentWeightKg == null || targetWeightKg == null) return null;
    if (targetWeightKg < currentWeightKg) return GoalWeightDirection.loss;
    if (targetWeightKg > currentWeightKg) return GoalWeightDirection.gain;
    return null;
  }

  /// Returns the direction that is safe to consume downstream.
  ///
  /// Explicit Lose/Gain wins. A training-only path can derive direction from
  /// the target answer only while Body follow-ups are active. Maintain Weight
  /// is deliberately non-directional and never consumes a dormant target.
  GoalWeightDirection? effectiveDirectionFor({
    required AppMode? mode,
    required GoalIntentSelection selection,
    required double? currentWeightKg,
    required double? targetWeightKg,
  }) {
    final explicit = directionFor(mode: mode, selection: selection);
    if (explicit != null) return explicit;
    if (!shouldCollectTargetWeight(mode: mode, selection: selection)) {
      return null;
    }
    return directionFromTarget(
      currentWeightKg: currentWeightKg,
      targetWeightKg: targetWeightKg,
    );
  }

  bool shouldCollectTargetWeight({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) {
    if (mode == null || selection.goals.isEmpty) return false;

    // Canonical user_body_goals forbids target/pace values for Maintain Weight.
    // Keep this no-schema follow-up coherent even when training goals coexist.
    if (selection.contains(GoalIntent.maintainWeight)) return false;

    return selection.goals.any((goal) => switch (goal) {
          GoalIntent.loseWeight ||
          GoalIntent.gainWeight ||
          GoalIntent.buildMuscle ||
          GoalIntent.getStronger ||
          GoalIntent.improveEndurance ||
          GoalIntent.stayFit => true,
          GoalIntent.maintainWeight || GoalIntent.recomposition => false,
        });
  }

  bool shouldCollectGoalPace({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      shouldCollectTargetWeight(mode: mode, selection: selection);

  /// Compatibility name retained for callers/tests that predate the
  /// `shouldCollect*` flow-plan API.
  bool requiresTargetWeight({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      shouldCollectTargetWeight(mode: mode, selection: selection);

  /// Compatibility name retained for callers/tests that predate the
  /// `shouldCollect*` flow-plan API.
  bool requiresGoalPace({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      shouldCollectGoalPace(mode: mode, selection: selection);
}

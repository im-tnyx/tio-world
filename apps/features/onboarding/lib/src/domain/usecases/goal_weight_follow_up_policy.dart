import 'package:tio_shared/shared.dart';

import '../models/models.dart';

/// Single source of truth for body-weight follow-up semantics in onboarding.
///
/// Direction is derived only from the user's explicit [GoalIntentSelection].
/// Measurements, BMI, target/current weight deltas, and training-only intents
/// must never invent a body-weight direction.
class GoalWeightFollowUpPolicy {
  const GoalWeightFollowUpPolicy();

  GoalWeightDirection? directionFor({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) {
    if (mode == null) return null;

    return switch (mode) {
      AppMode.nutrition => switch (selection.primaryGoal) {
          GoalIntent.loseWeight => GoalWeightDirection.loss,
          GoalIntent.gainWeight => GoalWeightDirection.gain,
          _ => null,
        },
      AppMode.workout || AppMode.hybrid =>
        selection.contains(GoalIntent.loseWeight)
            ? GoalWeightDirection.loss
            : null,
    };
  }

  bool shouldCollectTargetWeight({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      directionFor(mode: mode, selection: selection) != null;

  bool shouldCollectGoalPace({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      directionFor(mode: mode, selection: selection) != null;

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

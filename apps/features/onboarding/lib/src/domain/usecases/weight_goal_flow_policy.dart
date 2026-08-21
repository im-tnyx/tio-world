import 'package:tio_shared/shared.dart';

import '../models/models.dart';

/// Resolves whether onboarding should collect a target body weight and weekly
/// body-weight pace for the current explicit Goal selection.
///
/// This policy never infers a goal from measurements. It only interprets the
/// approved onboarding GoalIntent contract.
class WeightGoalFlowPolicy {
  const WeightGoalFlowPolicy();

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

  GoalIntent? activeWeightGoal({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) {
    return switch (directionFor(mode: mode, selection: selection)) {
      GoalWeightDirection.loss => GoalIntent.loseWeight,
      GoalWeightDirection.gain => GoalIntent.gainWeight,
      null => null,
    };
  }

  bool requiresTargetWeight({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      directionFor(mode: mode, selection: selection) != null;

  bool requiresGoalPace({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      directionFor(mode: mode, selection: selection) != null;
}

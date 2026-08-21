import 'package:tio_shared/shared.dart';

import '../models/models.dart';

/// Resolves whether onboarding should collect a target body weight and weekly
/// body-weight pace for the current explicit Goal selection.
///
/// This policy never infers a goal from measurements. It only interprets the
/// approved onboarding GoalIntent contract.
class WeightGoalFlowPolicy {
  const WeightGoalFlowPolicy();

  GoalIntent? activeWeightGoal({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) {
    if (mode == null) return null;

    return switch (mode) {
      AppMode.nutrition => switch (selection.primaryGoal) {
          GoalIntent.loseWeight => GoalIntent.loseWeight,
          GoalIntent.gainWeight => GoalIntent.gainWeight,
          _ => null,
        },
      AppMode.workout || AppMode.hybrid =>
        selection.contains(GoalIntent.loseWeight)
            ? GoalIntent.loseWeight
            : null,
    };
  }

  bool requiresTargetWeight({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      activeWeightGoal(mode: mode, selection: selection) != null;

  bool requiresGoalPace({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) =>
      activeWeightGoal(mode: mode, selection: selection) != null;
}

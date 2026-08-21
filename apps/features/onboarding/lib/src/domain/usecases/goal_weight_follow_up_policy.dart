import 'package:tio_shared/shared.dart';

import '../models/goal_intent.dart';
import '../models/goal_weight_direction.dart';

/// Decides whether onboarding should collect Target Weight and Goal Pace.
///
/// Eligibility comes only from explicit GoalIntentSelection. Numeric weight
/// differences and BMI never decide the user's goal direction.
class GoalWeightFollowUpPolicy {
  const GoalWeightFollowUpPolicy();

  GoalWeightDirection? directionFor({
    required AppMode? mode,
    required GoalIntentSelection selection,
  }) {
    if (mode == null) return null;

    if (mode == AppMode.nutrition) {
      return switch (selection.primaryGoal) {
        GoalIntent.loseWeight => GoalWeightDirection.loss,
        GoalIntent.gainWeight => GoalWeightDirection.gain,
        _ => null,
      };
    }

    return selection.contains(GoalIntent.loseWeight)
        ? GoalWeightDirection.loss
        : null;
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
}

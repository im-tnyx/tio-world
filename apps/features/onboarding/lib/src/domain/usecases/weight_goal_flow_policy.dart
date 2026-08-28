import 'goal_weight_follow_up_policy.dart';

/// Compatibility name retained while active callers converge on
/// [GoalWeightFollowUpPolicy]. Both resolve only explicit Goal intent.
@Deprecated('Use GoalWeightFollowUpPolicy.')
class WeightGoalFlowPolicy extends GoalWeightFollowUpPolicy {
  const WeightGoalFlowPolicy();
}

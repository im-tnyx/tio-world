import 'package:tio_shared/shared.dart';

import '../models/models.dart';
import 'goal_weight_follow_up_policy.dart';

class BuildTargetsFlowPlanUseCase {
  const BuildTargetsFlowPlanUseCase({
    this.followUpPolicy = const GoalWeightFollowUpPolicy(),
  });

  /// Retained as source-compatible construction surface during O3C.
  /// Goal Pace eligibility is now consumed by Body Goal, not Targets.
  final GoalWeightFollowUpPolicy followUpPolicy;

  TargetsFlowPlan call({
    required AppMode? mode,
    required GoalIntentSelection goalSelection,
  }) {
    return const TargetsFlowPlan();
  }

  TargetStepId reconcileCurrentStep({
    required TargetStepId currentStepId,
    required TargetsFlowPlan previousPlan,
    required TargetsFlowPlan nextPlan,
  }) {
    if (nextPlan.contains(currentStepId)) return currentStepId;

    final previousIndex = previousPlan.indexOf(currentStepId);
    for (var index = previousIndex - 1; index >= 0; index--) {
      final candidate = previousPlan.steps[index];
      if (nextPlan.contains(candidate)) return candidate;
    }

    return nextPlan.steps.first;
  }
}

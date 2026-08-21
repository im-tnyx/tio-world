import 'package:tio_shared/shared.dart';

import '../models/models.dart';
import 'goal_weight_follow_up_policy.dart';

class BuildTargetsFlowPlanUseCase {
  const BuildTargetsFlowPlanUseCase({
    this.followUpPolicy = const GoalWeightFollowUpPolicy(),
  });

  final GoalWeightFollowUpPolicy followUpPolicy;

  TargetsFlowPlan call({
    required AppMode? mode,
    required GoalIntentSelection goalSelection,
  }) {
    final includeGoalPace = followUpPolicy.shouldCollectGoalPace(
      mode: mode,
      selection: goalSelection,
    );

    return TargetsFlowPlan(
      steps: [
        for (final step in TargetsFlowPlan.orderedSteps)
          if (step != TargetStepId.goalPace || includeGoalPace) step,
      ],
    );
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

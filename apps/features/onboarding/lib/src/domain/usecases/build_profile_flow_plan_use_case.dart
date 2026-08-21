import 'package:tio_shared/shared.dart';

import '../models/models.dart';
import 'weight_goal_flow_policy.dart';

class BuildProfileFlowPlanUseCase {
  const BuildProfileFlowPlanUseCase({
    this.weightGoalPolicy = const WeightGoalFlowPolicy(),
  });

  final WeightGoalFlowPolicy weightGoalPolicy;

  ProfileFlowPlan call({
    required AppMode? mode,
    required GoalIntentSelection goalSelection,
  }) {
    final includeTargetWeight = weightGoalPolicy.requiresTargetWeight(
      mode: mode,
      selection: goalSelection,
    );

    return ProfileFlowPlan(
      steps: [
        for (final step in ProfileFlowPlan.orderedSteps)
          if (step != ProfileStepId.targetWeight || includeTargetWeight) step,
      ],
    );
  }

  ProfileStepId reconcileCurrentStep({
    required ProfileStepId currentStepId,
    required ProfileFlowPlan previousPlan,
    required ProfileFlowPlan nextPlan,
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

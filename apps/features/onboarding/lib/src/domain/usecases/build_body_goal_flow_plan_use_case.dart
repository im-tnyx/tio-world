import 'package:tio_shared/shared.dart';

import '../models/models.dart';
import 'goal_weight_follow_up_policy.dart';

class BuildBodyGoalFlowPlanUseCase {
  const BuildBodyGoalFlowPlanUseCase({
    this.followUpPolicy = const GoalWeightFollowUpPolicy(),
  });

  final GoalWeightFollowUpPolicy followUpPolicy;

  BodyGoalFlowPlan call({
    required AppMode? mode,
    required GoalIntentSelection goalSelection,
  }) {
    final includeWeightFollowUps = followUpPolicy.shouldCollectTargetWeight(
      mode: mode,
      selection: goalSelection,
    );
    final includeGoalPace = followUpPolicy.shouldCollectGoalPace(
      mode: mode,
      selection: goalSelection,
    );
    if (includeWeightFollowUps != includeGoalPace) {
      throw StateError(
        'Target Weight and Goal Pace must share Body Goal eligibility.',
      );
    }

    return BodyGoalFlowPlan(
      steps: [
        for (final step in BodyGoalFlowPlan.orderedSteps)
          if (includeWeightFollowUps ||
              (step != ProfileStepId.targetWeight &&
                  step != ProfileStepId.goalPace))
            step,
      ],
    );
  }

  ProfileStepId reconcileCurrentStep({
    required ProfileStepId currentStepId,
    required BodyGoalFlowPlan previousPlan,
    required BodyGoalFlowPlan nextPlan,
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

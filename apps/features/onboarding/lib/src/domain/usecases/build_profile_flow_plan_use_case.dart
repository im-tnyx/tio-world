import 'package:tio_shared/shared.dart';

import '../models/models.dart';
import 'goal_weight_follow_up_policy.dart';

class BuildProfileFlowPlanUseCase {
  const BuildProfileFlowPlanUseCase({
    this.followUpPolicy = const GoalWeightFollowUpPolicy(),
  });

  /// Retained for constructor/source compatibility while Body-owned follow-up
  /// semantics move to [BuildBodyGoalFlowPlanUseCase].
  final GoalWeightFollowUpPolicy followUpPolicy;

  ProfileFlowPlan call({
    required AppMode? mode,
    required GoalIntentSelection goalSelection,
  }) {
    return const ProfileFlowPlan();
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

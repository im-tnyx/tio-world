import '../models/models.dart';

class BuildWellnessFlowPlanUseCase {
  const BuildWellnessFlowPlanUseCase();

  WellnessFlowPlan call() => const WellnessFlowPlan();

  TargetStepId reconcileCurrentStep({
    required TargetStepId currentStepId,
    required WellnessFlowPlan previousPlan,
    required WellnessFlowPlan nextPlan,
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

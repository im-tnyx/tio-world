import '../models/models.dart';

class BuildNutritionProfileFlowPlanUseCase {
  const BuildNutritionProfileFlowPlanUseCase();

  NutritionProfileFlowPlan call() => const NutritionProfileFlowPlan();

  NutritionProfileStepId reconcileCurrentStep({
    required NutritionProfileStepId currentStepId,
    required NutritionProfileFlowPlan previousPlan,
    required NutritionProfileFlowPlan nextPlan,
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

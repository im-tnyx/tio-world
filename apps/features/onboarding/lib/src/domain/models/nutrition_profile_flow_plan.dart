import 'nutrition_profile_step_id.dart';

class NutritionProfileFlowPlan {
  const NutritionProfileFlowPlan({this.steps = orderedSteps});

  static const orderedSteps = <NutritionProfileStepId>[
    NutritionProfileStepId.dietType,
    NutritionProfileStepId.allergiesRestrictions,
  ];

  final List<NutritionProfileStepId> steps;

  int get stepCount => steps.length;

  bool contains(NutritionProfileStepId stepId) => steps.contains(stepId);

  int indexOf(NutritionProfileStepId stepId) => steps.indexOf(stepId);

  NutritionProfileStepId? previous(NutritionProfileStepId stepId) {
    final index = indexOf(stepId);
    return index <= 0 ? null : steps[index - 1];
  }

  NutritionProfileStepId? next(NutritionProfileStepId stepId) {
    final index = indexOf(stepId);
    if (index < 0 || index == steps.length - 1) return null;
    return steps[index + 1];
  }
}

import 'target_step_id.dart';

/// Ordered flow plan for the Targets onboarding section.
///
/// Steps 1–4 (bridge, stepTarget, sleepTarget, waterTarget) are real T1 screens.
/// Steps 5–6 (goalPace, nutritionTarget) are T2 compatibility — navigation-passable
/// but do not satisfy the Targets product readiness gate.
class TargetsFlowPlan {
  const TargetsFlowPlan({this.steps = orderedSteps});

  static const orderedSteps = <TargetStepId>[
    TargetStepId.bridge,
    TargetStepId.stepTarget,
    TargetStepId.sleepTarget,
    TargetStepId.waterTarget,
    TargetStepId.goalPace,
    TargetStepId.nutritionTarget,
  ];

  final List<TargetStepId> steps;

  int get stepCount => steps.length;

  bool contains(TargetStepId stepId) => steps.contains(stepId);

  int indexOf(TargetStepId stepId) => steps.indexOf(stepId);

  bool isFirst(TargetStepId stepId) => stepId == steps.first;

  bool isLast(TargetStepId stepId) => stepId == steps.last;

  TargetStepId? next(TargetStepId stepId) {
    final index = indexOf(stepId);
    if (index < 0 || index >= steps.length - 1) return null;
    return steps[index + 1];
  }

  TargetStepId? previous(TargetStepId stepId) {
    final index = indexOf(stepId);
    if (index <= 0) return null;
    return steps[index - 1];
  }

  /// CTA label for the current child step.
  ///
  /// [nutritionTarget] is the final child whose next global step is Review,
  /// so it shows 'Review'. All other child steps show 'Continue'.
  String primaryActionLabel(TargetStepId stepId) {
    return stepId == TargetStepId.nutritionTarget ? 'Review' : 'Continue';
  }
}

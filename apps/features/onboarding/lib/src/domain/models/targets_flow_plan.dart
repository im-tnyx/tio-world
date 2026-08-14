import 'target_step_id.dart';

/// Ordered flow plan for the Targets onboarding section.
///
/// Steps 1–4 (bridge, stepTarget, sleepTarget, waterTarget) are real T1 screens.
/// Steps 5–6 (goalPace, nutritionTarget) are T2 compatibility — navigation-passable
/// but do not satisfy the Targets product readiness gate.
class TargetsFlowPlan {
  const TargetsFlowPlan();

  static const orderedSteps = <TargetStepId>[
    TargetStepId.bridge,
    TargetStepId.stepTarget,
    TargetStepId.sleepTarget,
    TargetStepId.waterTarget,
    TargetStepId.goalPace,
    TargetStepId.nutritionTarget,
  ];

  int get stepCount => orderedSteps.length;

  int indexOf(TargetStepId stepId) => orderedSteps.indexOf(stepId);

  bool isFirst(TargetStepId stepId) => stepId == orderedSteps.first;

  bool isLast(TargetStepId stepId) => stepId == orderedSteps.last;

  TargetStepId? next(TargetStepId stepId) {
    final index = indexOf(stepId);
    if (index < 0 || index >= orderedSteps.length - 1) return null;
    return orderedSteps[index + 1];
  }

  TargetStepId? previous(TargetStepId stepId) {
    final index = indexOf(stepId);
    if (index <= 0) return null;
    return orderedSteps[index - 1];
  }

  /// CTA label for the current child step.
  ///
  /// [nutritionTarget] is the final child whose next global step is Review,
  /// so it shows 'Review'. All other child steps show 'Continue'.
  String primaryActionLabel(TargetStepId stepId) {
    return stepId == TargetStepId.nutritionTarget ? 'Review' : 'Continue';
  }
}

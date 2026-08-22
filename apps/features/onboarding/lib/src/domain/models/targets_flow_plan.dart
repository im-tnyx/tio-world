import 'target_step_id.dart';

/// Ordered flow plan for the active Targets onboarding section.
///
/// Goal Pace is retained only in [legacyOrderedSteps] for draft/resume
/// compatibility. Canonical runtime ownership moved to Body Goal in O3C.
class TargetsFlowPlan {
  const TargetsFlowPlan({this.steps = orderedSteps});

  static const orderedSteps = <TargetStepId>[
    TargetStepId.bridge,
    TargetStepId.stepTarget,
    TargetStepId.sleepTarget,
    TargetStepId.waterTarget,
    TargetStepId.nutritionTarget,
  ];

  static const legacyOrderedSteps = <TargetStepId>[
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

  /// [nutritionTarget] remains the final active child before Review.
  String primaryActionLabel(TargetStepId stepId) {
    return stepId == TargetStepId.nutritionTarget ? 'Review' : 'Continue';
  }
}

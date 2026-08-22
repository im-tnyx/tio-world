import 'target_step_id.dart';

/// Ordered child flow for the active canonical Wellness onboarding section.
///
/// Stable [TargetStepId] identities are intentionally reused so existing
/// serialized draft cursors remain compatible while top-level semantic
/// ownership moves from legacy Targets to Wellness.
class WellnessFlowPlan {
  const WellnessFlowPlan({this.steps = orderedSteps});

  static const orderedSteps = <TargetStepId>[
    TargetStepId.bridge,
    TargetStepId.stepTarget,
    TargetStepId.sleepTarget,
    TargetStepId.waterTarget,
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
}

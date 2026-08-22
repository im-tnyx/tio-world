import 'target_step_id.dart';

/// Ordered flow plan for the active legacy Targets top-level section.
///
/// O3C moved Goal Pace to Body Goal. O4B moves Bridge/Steps/Sleep/Water to the
/// canonical Wellness section. [legacyOrderedSteps] retains the historical
/// child ordering exclusively for draft/resume migration.
class TargetsFlowPlan {
  const TargetsFlowPlan({this.steps = orderedSteps});

  static const orderedSteps = <TargetStepId>[
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

  String primaryActionLabel(TargetStepId stepId) {
    return stepId == TargetStepId.nutritionTarget ? 'Review' : 'Continue';
  }
}

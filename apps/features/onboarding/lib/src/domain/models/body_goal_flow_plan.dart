import 'profile_step_id.dart';

/// Typed child-flow contract for the canonical Body Goal onboarding section.
///
/// O3 deliberately reuses the existing persisted [ProfileStepId] screen
/// identities for draft cursor compatibility. This enum is a navigation
/// identity here; durable Profile ownership remains separate from Body data.
class BodyGoalFlowPlan {
  const BodyGoalFlowPlan({this.steps = orderedSteps});

  static const orderedSteps = <ProfileStepId>[
    ProfileStepId.currentWeight,
    ProfileStepId.goal,
    ProfileStepId.targetWeight,
    ProfileStepId.goalPace,
  ];

  final List<ProfileStepId> steps;

  int get stepCount => steps.length;

  bool contains(ProfileStepId stepId) => steps.contains(stepId);

  int indexOf(ProfileStepId stepId) => steps.indexOf(stepId);

  ProfileStepId? previous(ProfileStepId stepId) {
    final index = indexOf(stepId);
    return index <= 0 ? null : steps[index - 1];
  }

  ProfileStepId? next(ProfileStepId stepId) {
    final index = indexOf(stepId);
    if (index < 0 || index == steps.length - 1) return null;
    return steps[index + 1];
  }
}

import 'profile_step_id.dart';

/// Typed child-flow contract for the canonical Body Goal onboarding section.
///
/// O3 deliberately reuses the existing persisted [ProfileStepId] identities
/// for Goal/weight screens so old draft snapshots stay readable while the
/// top-level section boundary is migrated separately.
class BodyGoalFlowPlan {
  const BodyGoalFlowPlan({this.steps = orderedSteps});

  static const orderedSteps = <ProfileStepId>[
    ProfileStepId.goal,
    ProfileStepId.currentWeight,
    ProfileStepId.targetWeight,
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

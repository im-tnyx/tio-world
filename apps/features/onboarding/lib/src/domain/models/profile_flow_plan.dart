import 'profile_step_id.dart';

class ProfileFlowPlan {
  const ProfileFlowPlan({this.steps = orderedSteps});

  /// Active common Profile children owned by `userProfile`.
  static const orderedSteps = <ProfileStepId>[
    ProfileStepId.name,
    ProfileStepId.gender,
    ProfileStepId.age,
    ProfileStepId.measurementUnits,
    ProfileStepId.height,
    ProfileStepId.activity,
    ProfileStepId.healthConditions,
  ];

  /// Pre-O3 mixed order retained only to interpret legacy `profileBasics`
  /// resume checkpoints. Runtime navigation must use [orderedSteps].
  static const legacyOrderedSteps = <ProfileStepId>[
    ProfileStepId.name,
    ProfileStepId.gender,
    ProfileStepId.goal,
    ProfileStepId.age,
    ProfileStepId.measurementUnits,
    ProfileStepId.height,
    ProfileStepId.currentWeight,
    ProfileStepId.targetWeight,
    ProfileStepId.activity,
    ProfileStepId.healthConditions,
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

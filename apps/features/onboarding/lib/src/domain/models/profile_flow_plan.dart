import 'profile_step_id.dart';

class ProfileFlowPlan {
  const ProfileFlowPlan();

  static const orderedSteps = <ProfileStepId>[
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

  int indexOf(ProfileStepId stepId) => orderedSteps.indexOf(stepId);

  ProfileStepId? previous(ProfileStepId stepId) {
    final index = indexOf(stepId);
    return index <= 0 ? null : orderedSteps[index - 1];
  }

  ProfileStepId? next(ProfileStepId stepId) {
    final index = indexOf(stepId);
    if (index < 0 || index == orderedSteps.length - 1) return null;
    return orderedSteps[index + 1];
  }
}

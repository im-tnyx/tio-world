import 'onboarding_step_id.dart';

/// Stable persistence boundary for top-level Product Onboarding step identity.
///
/// Existing storage keys intentionally match the historical enum names so
/// schema-v2 drafts remain byte-compatible. New identities also receive
/// explicit keys here instead of relying on enum `.name` as persistence API.
class OnboardingStepIdCodec {
  const OnboardingStepIdCodec();

  String encode(OnboardingStepId stepId) => switch (stepId) {
        OnboardingStepId.mode => 'mode',
        OnboardingStepId.profileBasics => 'profileBasics',
        OnboardingStepId.mobile => 'mobile',
        OnboardingStepId.workoutIntro => 'workoutIntro',
        OnboardingStepId.workoutPreferences => 'workoutPreferences',
        OnboardingStepId.nutritionIntro => 'nutritionIntro',
        OnboardingStepId.nutritionPreferences => 'nutritionPreferences',
        OnboardingStepId.targets => 'targets',
        OnboardingStepId.review => 'review',
        OnboardingStepId.userProfile => 'userProfile',
        OnboardingStepId.bodyGoal => 'bodyGoal',
        OnboardingStepId.wellnessGoals => 'wellnessGoals',
        OnboardingStepId.nutritionProfile => 'nutritionProfile',
        OnboardingStepId.workoutProfile => 'workoutProfile',
        OnboardingStepId.nutritionGoals => 'nutritionGoals',
        OnboardingStepId.workoutTargets => 'workoutTargets',
        OnboardingStepId.healthConnections => 'healthConnections',
        OnboardingStepId.planBuilding => 'planBuilding',
      };

  OnboardingStepId? tryDecode(Object? storageValue) {
    if (storageValue is! String) return null;

    return switch (storageValue) {
      'mode' => OnboardingStepId.mode,
      'profileBasics' => OnboardingStepId.profileBasics,
      'mobile' => OnboardingStepId.mobile,
      'workoutIntro' => OnboardingStepId.workoutIntro,
      'workoutPreferences' => OnboardingStepId.workoutPreferences,
      'nutritionIntro' => OnboardingStepId.nutritionIntro,
      'nutritionPreferences' => OnboardingStepId.nutritionPreferences,
      'targets' => OnboardingStepId.targets,
      'review' => OnboardingStepId.review,
      'userProfile' => OnboardingStepId.userProfile,
      'bodyGoal' => OnboardingStepId.bodyGoal,
      'wellnessGoals' => OnboardingStepId.wellnessGoals,
      'nutritionProfile' => OnboardingStepId.nutritionProfile,
      'workoutProfile' => OnboardingStepId.workoutProfile,
      'nutritionGoals' => OnboardingStepId.nutritionGoals,
      'workoutTargets' => OnboardingStepId.workoutTargets,
      'healthConnections' => OnboardingStepId.healthConnections,
      'planBuilding' => OnboardingStepId.planBuilding,
      _ => null,
    };
  }

  OnboardingStepId decodeOr(
    Object? storageValue, {
    required OnboardingStepId fallback,
  }) =>
      tryDecode(storageValue) ?? fallback;
}

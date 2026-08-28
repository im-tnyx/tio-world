enum OnboardingStepId {
  // Legacy/runtime identities retained for existing flow and draft compatibility.
  mode,
  profileBasics,
  mobile,
  workoutIntro,
  nutritionIntro,
  nutritionPreferences,
  targets,
  review,

  // Canonical top-level identities, activated incrementally by migration slices.
  userProfile,
  bodyGoal,
  wellnessGoals,
  nutritionProfile,
  workoutProfile,
  nutritionGoals,
  workoutTargets,
  healthConnections,
  planBuilding;

  /// Source-compatibility alias for historical callers. Durable legacy
  /// `workoutPreferences` storage is decoded to [workoutProfile]. New writes
  /// use the canonical `workoutProfile` identity.
  static const OnboardingStepId workoutPreferences = workoutProfile;
}

enum OnboardingStepId {
  // Legacy/runtime identities retained for existing flow and draft compatibility.
  mode,
  profileBasics,
  mobile,
  workoutIntro,
  workoutPreferences,
  nutritionIntro,
  nutritionPreferences,
  targets,
  review,

  // Future top-level identities. Slice 1 defines identity only; later approved
  // slices activate these in the runtime flow.
  userProfile,
  bodyGoal,
  wellnessGoals,
  nutritionProfile,
  workoutProfile,
  nutritionGoals,
  workoutTargets,
  healthConnections,
  planBuilding,
}

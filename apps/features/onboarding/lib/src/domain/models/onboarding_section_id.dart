enum OnboardingSectionId {
  // Legacy/runtime identities retained for existing flow and draft compatibility.
  appMode,
  profile,
  mobile,
  workoutIntro,
  workout,
  nutritionIntro,
  nutrition,
  targets,
  review,

  // Future section boundaries. Slice 1 defines identity only; later approved
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

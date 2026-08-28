/// Explicit body-weight direction derived from the user's onboarding goal intent.
///
/// This is not inferred from current/target weight deltas. It only exists when
/// the selected onboarding goal explicitly calls for body-weight change.
enum GoalWeightDirection {
  loss,
  gain,
}

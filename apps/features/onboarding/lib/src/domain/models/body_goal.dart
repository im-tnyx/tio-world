/// Canonical onboarding choice for the user's body-composition direction.
///
/// This is intentionally separate from legacy [ProfileGoal] semantics so
/// workout and wellness intents are not mixed into Body Goal.
enum BodyGoal {
  loseWeight,
  gainWeight,
  maintainWeight,
  bodyRecomposition,
}

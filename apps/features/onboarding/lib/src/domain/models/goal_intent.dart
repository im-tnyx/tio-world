/// Onboarding-level intent shown by the unified Goal screen.
///
/// This is intentionally neutral: some intents describe body direction while
/// others describe training outcomes. Canonical Body / Nutrition / Workout
/// ownership must map these explicitly later instead of persisting this enum as
/// one mixed owner field.
enum GoalIntent {
  loseWeight,
  gainWeight,
  maintainWeight,
  recomposition,
  buildMuscle,
  getStronger,
  improveEndurance,
  stayFit,
}

/// Ordered onboarding selection contract for the unified Goal screen.
///
/// Nutrition uses only [primaryGoal]. Workout and Hybrid may additionally use
/// [supportingGoal] when the pair is compatible.
class GoalIntentSelection {
  const GoalIntentSelection({
    this.primaryGoal,
    this.supportingGoal,
  });

  final GoalIntent? primaryGoal;
  final GoalIntent? supportingGoal;

  bool contains(GoalIntent goal) =>
      primaryGoal == goal || supportingGoal == goal;

  Iterable<GoalIntent> get goals sync* {
    final primary = primaryGoal;
    if (primary != null) yield primary;
    final supporting = supportingGoal;
    if (supporting != null) yield supporting;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalIntentSelection &&
          primaryGoal == other.primaryGoal &&
          supportingGoal == other.supportingGoal;

  @override
  int get hashCode => Object.hash(primaryGoal, supportingGoal);
}

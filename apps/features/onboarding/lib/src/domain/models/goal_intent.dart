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

  /// Legacy decode compatibility only. Recomposition is no longer presented as
  /// a standalone Goal card; new compound intent is expressed by multi-select.
  recomposition,
  buildMuscle,
  getStronger,
  improveEndurance,
  stayFit,
}

/// Ordered onboarding selection contract for the unified Goal screen.
///
/// Nutrition uses only [primaryGoal]. Workout and Hybrid may hold one weight
/// state plus up to two training priorities. [tertiaryGoal] is additive draft
/// state so the canonical Workout owner can keep primary + supporting training
/// goals without forcing Body and Workout intent into the same two slots.
class GoalIntentSelection {
  const GoalIntentSelection({
    this.primaryGoal,
    this.supportingGoal,
    this.tertiaryGoal,
  });

  final GoalIntent? primaryGoal;
  final GoalIntent? supportingGoal;
  final GoalIntent? tertiaryGoal;

  bool contains(GoalIntent goal) =>
      primaryGoal == goal || supportingGoal == goal || tertiaryGoal == goal;

  Iterable<GoalIntent> get goals sync* {
    final seen = <GoalIntent>{};
    final primary = primaryGoal;
    if (primary != null && seen.add(primary)) yield primary;
    final supporting = supportingGoal;
    if (supporting != null && seen.add(supporting)) yield supporting;
    final tertiary = tertiaryGoal;
    if (tertiary != null && seen.add(tertiary)) yield tertiary;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalIntentSelection &&
          primaryGoal == other.primaryGoal &&
          supportingGoal == other.supportingGoal &&
          tertiaryGoal == other.tertiaryGoal;

  @override
  int get hashCode => Object.hash(primaryGoal, supportingGoal, tertiaryGoal);
}

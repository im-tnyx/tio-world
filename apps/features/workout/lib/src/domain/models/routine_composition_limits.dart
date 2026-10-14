/// Product cap for newly authored Sets within each Routine Exercise entry.
///
/// Different Exercise entries in the same Routine have independent limits.
/// The database independently bounds stored positions to enforce this even
/// for callers that bypass or have not updated their Flutter UI.
abstract final class RoutineCompositionLimits {
  static const int maxSetsPerExercise = 8;
}

import 'package:tio_shared/shared.dart';

/// Product cap for newly authored Sets within each Routine Exercise entry.
///
/// Different Exercise entries in the same Routine have independent limits.
/// The database independently bounds stored positions to enforce this even
/// for callers that bypass or have not updated their Flutter UI.
abstract final class RoutineCompositionLimits {
  static const int maxSetsPerExercise = 8;

  /// STEPS has no canonical SetPrescription / SQL storage yet. Never
  /// reinterpret STEPS as reps/load or fabricate a target for Routine Save.
  /// The Exercise itself remains available in the normal Exercise Library.
  static bool supportsExerciseType(ExerciseType? type) =>
      type != ExerciseType.stepsDuration;
}

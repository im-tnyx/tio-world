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

  /// Protect authored Set targets when a Custom Exercise's measurement type
  /// changes on another device. Rest and Set Type belong to every profile.
  /// Missing/legacy untyped Custom definitions retain their existing draft
  /// semantics; caller separately checks the originally selected type.
  static bool targetsMatchExerciseType(
    ExerciseType? type,
    Iterable<SetPrescription> prescriptions,
  ) {
    if (!supportsExerciseType(type)) return false;
    for (final p in prescriptions) {
      final hasRepsOrLoad =
          p.reps != null || p.repsMax != null || p.loadKg != null;
      final hasDistance = p.distanceMeters != null;
      final hasDuration = p.durationSeconds != null;
      switch (type) {
        case ExerciseType.duration:
          if (hasRepsOrLoad || hasDistance) return false;
        case ExerciseType.distanceDuration:
          if (hasRepsOrLoad) return false;
        case ExerciseType.stepsDuration:
          return false;
        case null:
          break; // Existing nullable definition; do not manufacture a type.
        default:
          if (hasDistance || hasDuration) return false;
      }
    }
    return true;
  }
}

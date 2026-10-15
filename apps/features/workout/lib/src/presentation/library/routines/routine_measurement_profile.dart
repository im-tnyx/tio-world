import 'package:tio_shared/shared.dart';

import '../../../domain/repositories/routine_composition_repository.dart';

/// Preserve the *stored* legacy targets of an established Routine Exercise.
///
/// Some catalog IDs gained a distance/duration profile after old app versions
/// had already persisted only Reps/Load. Those values are not kilometers or
/// seconds. Until the user explicitly edits/converts them, render the actual
/// stored measurement shape rather than hiding it behind empty new columns.
/// Fresh typed Sets (including intentionally blank targets) still use the
/// catalog's canonical profile. Missing Exercise metadata stays unclassified.
ExerciseType? routineEntryMeasurementProfile(
  ExerciseType? canonical,
  List<RoutineCompositionSet> sets,
) {
  if (canonical == null) {
    // Custom definitions historically allow missing type. Reconstruct only
    // the visible measurement shape from stored targets; never mutate data.
    if (sets.any((set) => set.prescription.distanceMeters != null)) {
      return ExerciseType.distanceDuration;
    }
    if (sets.any((set) => set.prescription.durationSeconds != null)) {
      return ExerciseType.duration;
    }
    return null;
  }
  if (canonical != ExerciseType.distanceDuration &&
      canonical != ExerciseType.duration) {
    return canonical;
  }
  final hasLegacyTargets = sets.any((set) =>
      set.prescription.reps != null ||
      set.prescription.loadKg != null);
  final hasNewTargets = sets.any((set) =>
      set.prescription.distanceMeters != null ||
      set.prescription.durationSeconds != null);

  // Do not guess units or convert old Reps/Load to distance/time.
  return hasLegacyTargets && !hasNewTargets ? null : canonical;
}

import 'package:tio_shared/shared.dart';

import '../repositories/routine_composition_repository.dart';
import 'routine_composition_limits.dart';

/// Verified Routine content prepared for a Save-only local workout start.
///
/// This request deliberately contains no source identity for saved history; the
/// current Save contract remains ad-hoc.
final class WorkoutRoutineStartRequest {
  WorkoutRoutineStartRequest({
    required this.routine,
    required this.composition,
    required Map<ExerciseRef, Exercise> exercises,
  }) : exercises = Map.unmodifiable(exercises) {
    if (composition.routineId != routine.id ||
        (composition.name != null && composition.name != routine.name)) {
      throw ArgumentError('Routine start content does not match its Routine.');
    }
  }

  final Routine routine;
  final RoutineCompositionSnapshot composition;
  final Map<ExerciseRef, Exercise> exercises;

  bool get isExecutable {
    try {
      validate();
      return true;
    } on ArgumentError {
      return false;
    }
  }

  void validate() {
    final entries = composition.entries;
    if (entries.isEmpty || entries.length > 100) {
      throw ArgumentError('Routine is not executable.');
    }
    for (final entry in entries) {
      final exercise = exercises[entry.exercise];
      final prescriptions =
          entry.sets.map((set) => set.prescription).toList(growable: false);
      if (exercise == null ||
          exercise.ref != entry.exercise ||
          exercise.status != ExerciseStatus.active ||
          prescriptions.isEmpty ||
          prescriptions.length > RoutineCompositionLimits.maxSetsPerExercise ||
          !RoutineCompositionLimits.supportsExerciseType(
            exercise.exerciseType,
          ) ||
          !RoutineCompositionLimits.targetsMatchExerciseType(
            exercise.exerciseType,
            prescriptions,
          ) ||
          !RoutineCompositionLimits.hasValidSetOrder(prescriptions)) {
        throw ArgumentError('Routine content is not executable.');
      }
    }
  }
}

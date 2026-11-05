import 'package:tio_shared/shared.dart';

import 'routine_composition_limits.dart';

/// Deterministic rejection reasons when evaluating Routine execution readiness.
enum WorkoutReadinessRejectionReason {
  /// The Routine composition contains zero exercises.
  emptyRoutine,

  /// The Routine contains exercises but zero total prescribed sets.
  noExecutableSets,

  /// An exercise referenced in the composition could not be found or is archived.
  missingExercise,

  /// An exercise uses a measurement profile not supported by the current engine.
  unsupportedMeasurementProfile,

  /// The composition violates set limits, ordering, or profile target rules.
  invalidRoutineComposition,

  /// The Routine does not belong to the specified Program, or context is invalid.
  invalidOwnershipContext,
}

/// Sealed result of a workout execution readiness evaluation.
sealed class WorkoutExecutionReadiness {
  const WorkoutExecutionReadiness();

  /// Whether the evaluated Routine is ready for immediate active workout execution.
  bool get isReady => this is WorkoutExecutionReady;
}

/// Success result containing the frozen [WorkoutSessionSnapshot] ready for execution.
final class WorkoutExecutionReady extends WorkoutExecutionReadiness {
  const WorkoutExecutionReady({required this.snapshot});

  /// Frozen snapshot of the routine, program and exercises ready to start.
  final WorkoutSessionSnapshot snapshot;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExecutionReady && other.snapshot == snapshot;

  @override
  int get hashCode => snapshot.hashCode;
}

/// Failure result detailing why the Routine cannot be executed.
final class WorkoutExecutionRejected extends WorkoutExecutionReadiness {
  const WorkoutExecutionRejected({
    required this.reason,
    required this.message,
    this.exerciseRef,
    this.entryIndex,
  });

  /// Specific failure classification.
  final WorkoutReadinessRejectionReason reason;

  /// User-facing or diagnostic explanation.
  final String message;

  /// Offending Exercise identity, if failure is exercise-specific.
  final ExerciseRef? exerciseRef;

  /// 0-based index of the offending exercise occurrence in the Routine composition.
  final int? entryIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExecutionRejected &&
          other.reason == reason &&
          other.message == message &&
          other.exerciseRef == exerciseRef &&
          other.entryIndex == entryIndex;

  @override
  int get hashCode => Object.hash(reason, message, exerciseRef, entryIndex);
}

/// Deterministic domain validator for active workout execution readiness.
///
/// Evaluates whether a Routine, Program and its composition are valid and eligible
/// to start an active workout session under the approved W7A execution profile.
abstract final class WorkoutReadinessValidator {
  /// Set of measurement profiles approved for the initial active workout engine.
  ///
  /// W7A approves Weight & Reps (`ExerciseType.weightReps`) and untyped/reps-load
  /// custom exercises (`null` exerciseType). Distance, duration, and steps profiles
  /// fail safely until their execution slices are approved.
  static bool isApprovedProfile(ExerciseType? type) {
    if (type == null) return true; // Default Reps/Load custom exercise
    return type == ExerciseType.weightReps;
  }

  /// Evaluates readiness for execution.
  ///
  /// Returns [WorkoutExecutionReady] with a frozen [WorkoutSessionSnapshot] on success,
  /// or [WorkoutExecutionRejected] on any eligibility failure.
  static WorkoutExecutionReadiness evaluate({
    required String userId,
    required Program program,
    required Routine routine,
    required RoutineComposition composition,
    required Map<ExerciseRef, Exercise> resolvedExercises,
    DateTime? evaluationTimeUtc,
  }) {
    // 1. Program & Routine relationship check
    if (routine.programId != program.id) {
      return const WorkoutExecutionRejected(
        reason: WorkoutReadinessRejectionReason.invalidOwnershipContext,
        message: 'Routine does not belong to the specified Program.',
      );
    }
    if (composition.routineId != routine.id) {
      return const WorkoutExecutionRejected(
        reason: WorkoutReadinessRejectionReason.invalidOwnershipContext,
        message: 'Composition does not match Routine identity.',
      );
    }

    // 2. Empty Routine check
    if (composition.exercises.isEmpty) {
      return const WorkoutExecutionRejected(
        reason: WorkoutReadinessRejectionReason.emptyRoutine,
        message: 'Routine contains no exercises to perform.',
      );
    }

    // 3. Executable sets check
    final totalSets = composition.exercises.fold<int>(
      0,
      (sum, entry) => sum + entry.sets.length,
    );
    if (totalSets == 0) {
      return const WorkoutExecutionRejected(
        reason: WorkoutReadinessRejectionReason.noExecutableSets,
        message: 'Routine contains no executable sets.',
      );
    }

    // 4. Per-exercise and set prescription validation
    final snapshots = <SessionExerciseSnapshot>[];
    for (var i = 0; i < composition.exercises.length; i++) {
      final entry = composition.exercises[i];
      final exercise = resolvedExercises[entry.exercise];

      if (exercise == null) {
        return WorkoutExecutionRejected(
          reason: WorkoutReadinessRejectionReason.missingExercise,
          message: 'Exercise ${entry.exercise} could not be resolved.',
          exerciseRef: entry.exercise,
          entryIndex: i,
        );
      }

      if (exercise.status == ExerciseStatus.archived) {
        return WorkoutExecutionRejected(
          reason: WorkoutReadinessRejectionReason.missingExercise,
          message: 'Exercise "${exercise.displayName}" is archived and cannot be started.',
          exerciseRef: entry.exercise,
          entryIndex: i,
        );
      }

      // Measurement profile candidate check (Weight & Reps only for W7A)
      if (!isApprovedProfile(exercise.exerciseType)) {
        return WorkoutExecutionRejected(
          reason: WorkoutReadinessRejectionReason.unsupportedMeasurementProfile,
          message:
              'Exercise "${exercise.displayName}" uses unsupported measurement profile (${exercise.exerciseType?.storageValue}). Only Weight & Reps is supported in this slice.',
          exerciseRef: entry.exercise,
          entryIndex: i,
        );
      }

      // Set limits
      if (entry.sets.length > RoutineCompositionLimits.maxSetsPerExercise) {
        return WorkoutExecutionRejected(
          reason: WorkoutReadinessRejectionReason.invalidRoutineComposition,
          message:
              'Exercise "${exercise.displayName}" exceeds the maximum of ${RoutineCompositionLimits.maxSetsPerExercise} sets.',
          exerciseRef: entry.exercise,
          entryIndex: i,
        );
      }

      // Set ordering (warm-up sets before non-warm-up)
      if (!RoutineCompositionLimits.hasValidSetOrder(entry.sets)) {
        return WorkoutExecutionRejected(
          reason: WorkoutReadinessRejectionReason.invalidRoutineComposition,
          message:
              'Exercise "${exercise.displayName}" has warm-up sets placed after working sets.',
          exerciseRef: entry.exercise,
          entryIndex: i,
        );
      }

      // Target matching
      if (!RoutineCompositionLimits.targetsMatchExerciseType(
        exercise.exerciseType,
        entry.sets,
      )) {
        return WorkoutExecutionRejected(
          reason: WorkoutReadinessRejectionReason.invalidRoutineComposition,
          message:
              'Exercise "${exercise.displayName}" prescribed targets do not match its measurement profile.',
          exerciseRef: entry.exercise,
          entryIndex: i,
        );
      }

      snapshots.add(
        SessionExerciseSnapshot(
          exerciseRef: entry.exercise,
          displayName: exercise.displayName,
          exerciseType: exercise.exerciseType,
          occurrenceIndex: i,
          prescribedSets: entry.sets,
        ),
      );
    }

    final evalTime = evaluationTimeUtc ?? DateTime.timestamp();
    final snapshot = WorkoutSessionSnapshot(
      routineId: routine.id,
      routineName: routine.name,
      programId: program.id,
      capturedAtUtc: evalTime,
      exercises: snapshots,
    );

    return WorkoutExecutionReady(snapshot: snapshot);
  }
}

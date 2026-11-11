import 'exercise_ref.dart';
import 'exercise_type.dart';
import 'program_id.dart';
import 'routine_id.dart';
import 'set_prescription.dart';

/// Immutable historical snapshot of one Exercise occurrence at session start.
///
/// Freezes exercise metadata and prescribed set configuration so that future
/// modifications or deletions of the source Routine or Exercise do not mutate
/// historical workout sessions.
final class SessionExerciseSnapshot {
  SessionExerciseSnapshot({
    required this.exerciseRef,
    required String displayName,
    this.exerciseType,
    required this.occurrenceIndex,
    List<SetPrescription> prescribedSets = const [],
  })  : displayName = _requireNonBlankText(displayName, 'displayName'),
        prescribedSets = List<SetPrescription>.unmodifiable(
          List<SetPrescription>.of(prescribedSets),
        ) {
    if (occurrenceIndex < 0) {
      throw ArgumentError.value(
        occurrenceIndex,
        'occurrenceIndex',
        'must be non-negative',
      );
    }
  }

  /// Canonical catalog or user-created Exercise reference.
  final ExerciseRef exerciseRef;

  /// Display name captured from the Exercise definition at start time.
  final String displayName;

  /// Measurement profile captured at start time.
  final ExerciseType? exerciseType;

  /// 0-based order of this exercise occurrence in the Routine composition.
  final int occurrenceIndex;

  /// Prescribed sets captured from the Routine composition at start time.
  final List<SetPrescription> prescribedSets;

  static String _requireNonBlankText(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        name,
        'must contain at least one non-whitespace character',
      );
    }
    return value;
  }

  static bool _listsEqual(List<SetPrescription> a, List<SetPrescription> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionExerciseSnapshot &&
          other.exerciseRef == exerciseRef &&
          other.displayName == displayName &&
          other.exerciseType == exerciseType &&
          other.occurrenceIndex == occurrenceIndex &&
          _listsEqual(other.prescribedSets, prescribedSets);

  @override
  int get hashCode => Object.hash(
        exerciseRef,
        displayName,
        exerciseType,
        occurrenceIndex,
        Object.hashAll(prescribedSets),
      );
}

/// Immutable frozen snapshot of the source Routine captured at session start.
final class WorkoutSessionSnapshot {
  WorkoutSessionSnapshot({
    required this.routineId,
    required String routineName,
    required this.programId,
    required DateTime capturedAtUtc,
    List<SessionExerciseSnapshot> exercises = const [],
  })  : routineName = _requireNonBlankText(routineName, 'routineName'),
        capturedAtUtc = _requireUtc(capturedAtUtc, 'capturedAtUtc'),
        exercises = List<SessionExerciseSnapshot>.unmodifiable(
          List<SessionExerciseSnapshot>.of(exercises),
        );

  /// Identity of the source Routine.
  final RoutineId routineId;

  /// Routine name frozen at session start.
  final String routineName;

  /// Owning Program identity frozen at session start.
  final ProgramId programId;

  /// UTC instant when this snapshot was frozen.
  final DateTime capturedAtUtc;

  /// Ordered exercise occurrence snapshots.
  final List<SessionExerciseSnapshot> exercises;

  static String _requireNonBlankText(String value, String name) {
    if (value.trim().isEmpty) {
      throw ArgumentError.value(
        value,
        name,
        'must contain at least one non-whitespace character',
      );
    }
    return value;
  }

  static DateTime _requireUtc(DateTime dt, String name) {
    if (!dt.isUtc) {
      throw ArgumentError.value(dt, name, 'must be a UTC DateTime');
    }
    return dt;
  }

  static bool _exercisesEqual(
    List<SessionExerciseSnapshot> a,
    List<SessionExerciseSnapshot> b,
  ) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionSnapshot &&
          other.routineId == routineId &&
          other.routineName == routineName &&
          other.programId == programId &&
          other.capturedAtUtc == capturedAtUtc &&
          _exercisesEqual(other.exercises, exercises);

  @override
  int get hashCode => Object.hash(
        routineId,
        routineName,
        programId,
        capturedAtUtc,
        Object.hashAll(exercises),
      );
}

import 'exercise_ref.dart';
import 'workout_id_validation.dart';

/// One performed set recorded during a WorkoutSession.
///
/// Distinct from [SetPrescription] (planned template truth): this captures
/// actual execution data. Weight is stored in canonical kilograms.
final class PerformedSet {
  PerformedSet({
    required String id,
    required this.exerciseRef,
    required this.sessionExerciseIndex,
    required this.setIndex,
    int? reps,
    double? loadKg,
    int? durationSeconds,
    double? distanceMeters,
    DateTime? completedAtUtc,
    this.isSkipped = false,
    String? notes,
  })  : id = requireCanonicalUuid(id, 'id'),
        reps = _validateReps(reps),
        loadKg = _validateLoadKg(loadKg),
        durationSeconds = _validateDurationSeconds(durationSeconds),
        distanceMeters = _validateDistanceMeters(distanceMeters),
        completedAtUtc = _validateCompletedAtUtc(completedAtUtc),
        notes = _normalizeNotes(notes) {
    if (sessionExerciseIndex < 0) {
      throw ArgumentError.value(
        sessionExerciseIndex,
        'sessionExerciseIndex',
        'must be non-negative',
      );
    }
    if (setIndex < 0) {
      throw ArgumentError.value(setIndex, 'setIndex', 'must be non-negative');
    }
  }

  /// Unique client-generated UUID for this performed set entry.
  final String id;

  /// Canonical catalog or user-created Exercise reference.
  final ExerciseRef exerciseRef;

  /// 0-based index of this Exercise occurrence within the session.
  ///
  /// Distinguishes repeated references to the same Exercise within a single
  /// workout routine.
  final int sessionExerciseIndex;

  /// 0-based set index for this Exercise occurrence.
  final int setIndex;

  /// Actual repetitions completed. Zero represents an attempted set with 0 reps;
  /// null represents an unlogged or non-reps set.
  final int? reps;

  /// Actual external load in canonical kilograms.
  final double? loadKg;

  /// Actual duration in whole seconds.
  final int? durationSeconds;

  /// Actual distance in meters.
  final double? distanceMeters;

  /// UTC instant when this set was marked finished.
  final DateTime? completedAtUtc;

  /// Whether this set was skipped during the session.
  final bool isSkipped;

  /// Optional per-set note recorded by the athlete.
  final String? notes;

  static int? _validateReps(int? value) {
    if (value != null && (value < 0 || value > 2147483647)) {
      throw ArgumentError.value(
        value,
        'reps',
        'must be non-negative and within 32-bit signed integer limits',
      );
    }
    return value;
  }

  static double? _validateLoadKg(double? value) {
    if (value != null && (!value.isFinite || value < 0)) {
      throw ArgumentError.value(
        value,
        'loadKg',
        'must be finite and non-negative',
      );
    }
    return value;
  }

  static int? _validateDurationSeconds(int? value) {
    if (value != null && (value < 0 || value > 2147483647)) {
      throw ArgumentError.value(
        value,
        'durationSeconds',
        'must be non-negative and within 32-bit signed integer limits',
      );
    }
    return value;
  }

  static double? _validateDistanceMeters(double? value) {
    if (value != null && (!value.isFinite || value < 0)) {
      throw ArgumentError.value(
        value,
        'distanceMeters',
        'must be finite and non-negative',
      );
    }
    return value;
  }

  static DateTime? _validateCompletedAtUtc(DateTime? value) {
    if (value != null && !value.isUtc) {
      throw ArgumentError.value(
        value,
        'completedAtUtc',
        'must be a UTC DateTime',
      );
    }
    return value;
  }

  static String? _normalizeNotes(String? value) {
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PerformedSet &&
          other.id == id &&
          other.exerciseRef == exerciseRef &&
          other.sessionExerciseIndex == sessionExerciseIndex &&
          other.setIndex == setIndex &&
          other.reps == reps &&
          other.loadKg == loadKg &&
          other.durationSeconds == durationSeconds &&
          other.distanceMeters == distanceMeters &&
          other.completedAtUtc == completedAtUtc &&
          other.isSkipped == isSkipped &&
          other.notes == notes;

  @override
  int get hashCode => Object.hash(
        id,
        exerciseRef,
        sessionExerciseIndex,
        setIndex,
        reps,
        loadKg,
        durationSeconds,
        distanceMeters,
        completedAtUtc,
        isSkipped,
        notes,
      );
}

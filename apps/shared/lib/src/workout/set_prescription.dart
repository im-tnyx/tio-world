/// Set classification for an unperformed Routine template prescription.
/// Identical values serialize to the approved PostgreSQL CHECK strings.
enum RoutineSetType {
  normal('normal'),
  warmUp('warm_up'),
  failure('failure'),
  drop('drop');

  const RoutineSetType(this.wireValue);
  final String wireValue;

  static RoutineSetType fromWire(String value) {
    for (final type in values) {
      if (type.wireValue == value) return type;
    }
    throw ArgumentError.value(value, 'setType', 'unknown Routine Set type');
  }
}

/// Canonical template values for one prescribed set.
///
/// This is planned/template truth only. Actual performed values belong to a
/// future `PerformedSet` / `WorkoutSession` contract.
final class SetPrescription {
  SetPrescription({
    int? reps,
    int? repsMax,
    RoutineSetType setType = RoutineSetType.normal,
    double? loadKg,
    double? distanceMeters,
    int? durationSeconds,
    int? restSeconds,
  })  : reps = _requirePositiveReps(reps),
        repsMax = _requireValidMaximum(reps, repsMax),
        setType = setType,
        loadKg = _validateLoadKg(loadKg),
        distanceMeters = _validateDistanceMeters(distanceMeters),
        durationSeconds = _validateDurationSeconds(durationSeconds),
        restSeconds = _validateRestSeconds(restSeconds);

  /// Nullable prescribed target (fixed) or Rep Range minimum.
  /// An unperformed Routine template may intentionally leave it unspecified.
  /// Null must be saved and restored as null, never 1 or 0.
  final int? reps;

  /// Nullable maximum. Present (even equal to [reps]) means Rep Range.
  final int? repsMax;

  /// Warm Up / Normal / Failure / Drop classification (template only).
  final RoutineSetType setType;

  bool get isRepRange => repsMax != null;

  /// Optional planned external load in canonical kilograms.
  ///
  /// `null` means no load target is specified. Zero is an explicit value.
  final double? loadKg;

  /// Optional distance target stored in canonical meters. Zero is explicit;
  /// null represents an unspecified KM target on a Routine template.
  final double? distanceMeters;

  /// Optional duration target stored as whole canonical seconds. Null means
  /// unspecified TIME, and zero is an explicit duration.
  final int? durationSeconds;

  /// Optional planned rest after this set, in seconds.
  ///
  /// `null` means no rest target is specified. Zero is an explicit value.
  final int? restSeconds;

  static int? _requirePositiveReps(int? value) {
    if (value != null && (value <= 0 || value > 2147483647)) {
      throw ArgumentError.value(value, 'reps',
          'must be positive and within int32 when provided');
    }
    return value;
  }

  static int? _requireValidMaximum(int? minimum, int? maximum) {
    if (maximum == null) return null;
    if (minimum == null || maximum < minimum || maximum <= 0 ||
        maximum > 2147483647) {
      throw ArgumentError.value(maximum, 'repsMax',
          'requires a positive minimum and must be within int32');
    }
    return maximum;
  }

  static double? _validateDistanceMeters(double? value) {
    if (value == null) return null;
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(value, 'distanceMeters',
          'must be finite and nonnegative');
    }
    return value;
  }

  static int? _validateDurationSeconds(int? value) {
    if (value == null) return null;
    if (value < 0 || value > 2147483647) {
      throw ArgumentError.value(value, 'durationSeconds',
          'must be nonnegative and within int32');
    }
    return value;
  }

  static double? _validateLoadKg(double? value) {
    if (value == null) return null;
    if (!value.isFinite || value < 0) {
      throw ArgumentError.value(
        value,
        'loadKg',
        'must be finite and greater than or equal to zero',
      );
    }
    return value;
  }

  static int? _validateRestSeconds(int? value) {
    if (value == null) return null;
    if (value < 0) {
      throw ArgumentError.value(
        value,
        'restSeconds',
        'must be greater than or equal to zero',
      );
    }
    return value;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SetPrescription &&
          other.reps == reps &&
          other.repsMax == repsMax &&
          other.setType == setType &&
          other.loadKg == loadKg &&
          other.distanceMeters == distanceMeters &&
          other.durationSeconds == durationSeconds &&
          other.restSeconds == restSeconds;

  @override
  int get hashCode => Object.hash(
      reps, repsMax, setType, loadKg, distanceMeters, durationSeconds, restSeconds,
    );
}

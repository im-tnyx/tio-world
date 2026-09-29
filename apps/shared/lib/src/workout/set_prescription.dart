/// Canonical template values for one prescribed set.
///
/// This is planned/template truth only. Actual performed values belong to a
/// future `PerformedSet` / `WorkoutSession` contract.
final class SetPrescription {
  SetPrescription({
    required int reps,
    double? loadKg,
    int? restSeconds,
  })  : reps = _requirePositiveReps(reps),
        loadKg = _validateLoadKg(loadKg),
        restSeconds = _validateRestSeconds(restSeconds);

  /// Planned repetition count.
  final int reps;

  /// Optional planned external load in canonical kilograms.
  ///
  /// `null` means no load target is specified. Zero is an explicit value.
  final double? loadKg;

  /// Optional planned rest after this set, in seconds.
  ///
  /// `null` means no rest target is specified. Zero is an explicit value.
  final int? restSeconds;

  static int _requirePositiveReps(int value) {
    if (value <= 0) {
      throw ArgumentError.value(value, 'reps', 'must be greater than zero');
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
          other.loadKg == loadKg &&
          other.restSeconds == restSeconds;

  @override
  int get hashCode => Object.hash(reps, loadKg, restSeconds);
}

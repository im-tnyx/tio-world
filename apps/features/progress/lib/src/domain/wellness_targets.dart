/// Canonical Wellness target values shared across onboarding and post-onboarding
/// health/progress surfaces.
///
/// Null means unknown/unset. The canonical owner must never replace a missing
/// persisted value with an onboarding UI default.
class WellnessTargetsData {
  const WellnessTargetsData({
    this.dailySteps,
    this.waterMl,
    this.sleepTargetMinutes,
    this.bedTimeMinutes,
    this.wakeTimeMinutes,
  });

  final int? dailySteps;
  final int? waterMl;
  final int? sleepTargetMinutes;

  /// Minutes since local midnight, in the inclusive range 0..1439.
  final int? bedTimeMinutes;

  /// Minutes since local midnight, in the inclusive range 0..1439.
  final int? wakeTimeMinutes;

  /// Validates backend-neutral canonical storage constraints.
  ///
  /// Product/UI ranges may be narrower. This contract mirrors the canonical
  /// owner semantics: numeric targets are nonnegative and clock values are
  /// minute-precise local times.
  void validate() {
    _requireNonnegative(dailySteps, 'dailySteps');
    _requireNonnegative(waterMl, 'waterMl');
    _requireNonnegative(sleepTargetMinutes, 'sleepTargetMinutes');
    _requireMinuteOfDay(bedTimeMinutes, 'bedTimeMinutes');
    _requireMinuteOfDay(wakeTimeMinutes, 'wakeTimeMinutes');
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WellnessTargetsData &&
            dailySteps == other.dailySteps &&
            waterMl == other.waterMl &&
            sleepTargetMinutes == other.sleepTargetMinutes &&
            bedTimeMinutes == other.bedTimeMinutes &&
            wakeTimeMinutes == other.wakeTimeMinutes;
  }

  @override
  int get hashCode => Object.hash(
        dailySteps,
        waterMl,
        sleepTargetMinutes,
        bedTimeMinutes,
        wakeTimeMinutes,
      );
}

/// Canonical Wellness owner boundary.
abstract interface class WellnessTargetsRepository {
  /// Returns the authenticated user's canonical Wellness row, or null when the
  /// user is signed out or no row exists.
  Future<WellnessTargetsData?> read();

  /// Replaces the authenticated user's canonical Wellness target values.
  /// Null fields are intentional clears, not requests for fabricated defaults.
  Future<void> upsert(WellnessTargetsData targets);
}

void _requireNonnegative(int? value, String name) {
  if (value != null && value < 0) {
    throw ArgumentError.value(value, name, 'Expected zero or greater.');
  }
}

void _requireMinuteOfDay(int? value, String name) {
  if (value != null && (value < 0 || value >= 24 * 60)) {
    throw ArgumentError.value(value, name, 'Expected minutes in range 0..1439.');
  }
}

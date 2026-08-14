/// Pure Dart helper to derive estimated target completion date from weight difference and pace.
///
/// Deterministic: callers can pass an explicit [now] timestamp for reproducible tests.
class GoalPaceTargetDateCalculator {
  const GoalPaceTargetDateCalculator._();

  /// Calculate the estimated target completion date.
  ///
  /// If [paceKgPerWeek] is <= 0 or weights are null or equal, returns [now].
  static DateTime calculateTargetDate({
    required double? currentWeightKg,
    required double? targetWeightKg,
    required double paceKgPerWeek,
    required DateTime now,
  }) {
    if (currentWeightKg == null ||
        targetWeightKg == null ||
        paceKgPerWeek <= 0) {
      return DateTime(now.year, now.month, now.day);
    }

    final weightDiff = (currentWeightKg - targetWeightKg).abs();
    if (weightDiff < 0.001) {
      return DateTime(now.year, now.month, now.day);
    }

    final weeksNeeded = weightDiff / paceKgPerWeek;
    final daysNeeded = (weeksNeeded * 7).round();

    final base = DateTime(now.year, now.month, now.day);
    return base.add(Duration(days: daysNeeded));
  }

  /// Calculate the number of days needed to reach target weight.
  static int calculateDaysNeeded({
    required double? currentWeightKg,
    required double? targetWeightKg,
    required double paceKgPerWeek,
  }) {
    if (currentWeightKg == null ||
        targetWeightKg == null ||
        paceKgPerWeek <= 0) {
      return 0;
    }

    final weightDiff = (currentWeightKg - targetWeightKg).abs();
    if (weightDiff < 0.001) return 0;

    final weeksNeeded = weightDiff / paceKgPerWeek;
    return (weeksNeeded * 7).round();
  }
}

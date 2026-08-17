/// Pure Dart helper for sleep schedule arithmetic.
///
/// All times are represented as minutes since midnight:
///   0    = 00:00
///   360  = 06:00
///   1320 = 22:00
///   1380 = 23:00
///
/// Cross-midnight arithmetic is handled correctly:
///   wake >= sleep → same day:  duration = wake - sleep
///   wake <  sleep → overnight: duration = (24*60 - sleep) + wake
///
/// This helper is onboarding-local infrastructure.
/// Migrate to the owning health/sleep domain when that package grows a domain layer.
class SleepScheduleHelper {
  const SleepScheduleHelper._();

  static const int minutesPerDay = 24 * 60;
  static const int minDurationMinutes = 4 * 60; // 240 — 4h
  static const int maxDurationMinutes = 12 * 60; // 720 — 12h

  /// Compute sleep duration in minutes from sleep and wake minutes-since-midnight.
  ///
  /// Handles cross-midnight automatically.
  /// Result is NOT clamped — use [clampDuration] if you need bounds enforcement.
  static int durationMinutes(int sleepTimeMinutes, int wakeTimeMinutes) {
    if (wakeTimeMinutes >= sleepTimeMinutes) {
      return wakeTimeMinutes - sleepTimeMinutes;
    }
    return minutesPerDay - sleepTimeMinutes + wakeTimeMinutes;
  }

  /// Clamp a duration to the valid slider range [240, 720].
  static int clampDuration(int minutes) =>
      minutes.clamp(minDurationMinutes, maxDurationMinutes);

  /// Convert minutes since midnight to "HH:mm" display string (24h).
  static String formatTime(int minutesSinceMidnight) {
    final normalized = minutesSinceMidnight % minutesPerDay;
    final h = normalized ~/ 60;
    final m = normalized % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// Parse "HH:mm" string to minutes since midnight.
  /// Returns 0 on invalid input.
  static int parseTime(String hhMm) {
    final parts = hhMm.split(':');
    final h = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
    final m = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
    return (h * 60 + m).clamp(0, minutesPerDay - 1);
  }

  /// Derive wake time (minutes since midnight) from sleep time + duration.
  static int wakeTimeFromSleepAndDuration(
    int sleepTimeMinutes,
    int durationMinutes,
  ) {
    return (sleepTimeMinutes + durationMinutes) % minutesPerDay;
  }

  /// Derive sleep time (minutes since midnight) from wake time + duration.
  ///
  /// May be cross-midnight: if wake < duration, sleep is the previous evening.
  static int sleepTimeFromWakeAndDuration(
    int wakeTimeMinutes,
    int durationMinutes,
  ) {
    return (wakeTimeMinutes - durationMinutes + minutesPerDay) % minutesPerDay;
  }

  /// Derive new wake time after sleep time changes, preserving current duration.
  static int adjustWakeOnSleepChange(
    int newSleepTimeMinutes,
    int currentDurationMinutes,
  ) {
    return wakeTimeFromSleepAndDuration(newSleepTimeMinutes, currentDurationMinutes);
  }

  /// Derive new duration after wake time changes; clamp to valid range.
  static int adjustDurationOnWakeChange(
    int sleepTimeMinutes,
    int newWakeTimeMinutes,
  ) {
    final raw = durationMinutes(sleepTimeMinutes, newWakeTimeMinutes);
    return clampDuration(raw);
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  group('SleepScheduleHelper', () {
    test('computes cross-midnight duration correctly', () {
      // 23:00 (1380) -> 07:00 (420) = 480 min (8h)
      expect(SleepScheduleHelper.durationMinutes(1380, 420), 480);

      // 22:00 (1320) -> 06:00 (360) = 480 min (8h)
      expect(SleepScheduleHelper.durationMinutes(1320, 360), 480);

      // 23:30 (1410) -> 07:30 (450) = 480 min (8h)
      expect(SleepScheduleHelper.durationMinutes(1410, 450), 480);
    });

    test('computes same-day duration correctly', () {
      // 06:00 (360) -> 14:00 (840) = 480 min (8h)
      expect(SleepScheduleHelper.durationMinutes(360, 840), 480);

      // 00:00 (0) -> 08:00 (480) = 480 min (8h)
      expect(SleepScheduleHelper.durationMinutes(0, 480), 480);
    });

    test('derives wake time from sleep and duration across midnight', () {
      // Sleep 22:00 (1320) + 480 min (8h) = Wake 06:00 (360)
      expect(
        SleepScheduleHelper.wakeTimeFromSleepAndDuration(1320, 480),
        360,
      );

      // Sleep 23:30 (1410) + 450 min (7.5h) = Wake 07:00 (420)
      expect(
        SleepScheduleHelper.wakeTimeFromSleepAndDuration(1410, 450),
        420,
      );
    });

    test('derives sleep time from wake and duration across midnight', () {
      // Wake 06:00 (360) - 480 min (8h) = Sleep 22:00 (1320)
      expect(
        SleepScheduleHelper.sleepTimeFromWakeAndDuration(360, 480),
        1320,
      );

      // Wake 08:00 (480) - 480 min (8h) = Sleep 00:00 (0)
      expect(
        SleepScheduleHelper.sleepTimeFromWakeAndDuration(480, 480),
        0,
      );
    });

    test('adjusts wake time on sleep time change preserving duration', () {
      // Original: 22:00 (1320), duration 480. New sleep: 23:00 (1380).
      // New wake should be 07:00 (420).
      expect(
        SleepScheduleHelper.adjustWakeOnSleepChange(1380, 480),
        420,
      );
    });

    test('adjusts duration on wake time change and clamps to bounds', () {
      // Sleep 22:00 (1320). Wake changes to 08:00 (480) -> 10h = 600 min
      expect(
        SleepScheduleHelper.adjustDurationOnWakeChange(1320, 480),
        600,
      );

      // Sleep 22:00 (1320). Wake changes to 00:00 (0) -> 2h = 120 min -> clamped to min (240 min / 4h)
      expect(
        SleepScheduleHelper.adjustDurationOnWakeChange(1320, 0),
        240,
      );
    });

    test('formats and parses time strings correctly', () {
      expect(SleepScheduleHelper.formatTime(1320), '22:00');
      expect(SleepScheduleHelper.formatTime(360), '06:00');
      expect(SleepScheduleHelper.formatTime(0), '00:00');

      expect(SleepScheduleHelper.parseTime('22:00'), 1320);
      expect(SleepScheduleHelper.parseTime('06:00'), 360);
      expect(SleepScheduleHelper.parseTime('00:00'), 0);
    });
  });
}

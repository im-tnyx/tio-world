import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('tioOrderedWeekdayLabels', () {
    test('a Monday start reads Monday through Sunday', () {
      expect(
        tioOrderedWeekdayLabels(
          firstDayOfWeek: DateTime.monday,
          localeName: 'en_US',
        ),
        <String>['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
      );
    });

    test('a Sunday start reads Sunday through Saturday', () {
      expect(
        tioOrderedWeekdayLabels(
          firstDayOfWeek: DateTime.sunday,
          localeName: 'en_US',
        ),
        <String>['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'],
      );
    });

    test('a mid-week start wraps around the end of the week', () {
      // The case the two-option design could not express: a plan whose cycle
      // begins on a Wednesday still gets a whole, correctly ordered week.
      expect(
        tioOrderedWeekdayLabels(
          firstDayOfWeek: DateTime.wednesday,
          localeName: 'en_US',
        ),
        <String>['WED', 'THU', 'FRI', 'SAT', 'SUN', 'MON', 'TUE'],
      );
      expect(
        tioOrderedWeekdayLabels(
          firstDayOfWeek: DateTime.saturday,
          localeName: 'en_US',
        ),
        <String>['SAT', 'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI'],
      );
    });

    test('every start day produces the same seven labels, rotated', () {
      final monday = tioOrderedWeekdayLabels(
        firstDayOfWeek: DateTime.monday,
        localeName: 'en_US',
      );

      for (var start = DateTime.monday; start <= DateTime.sunday; start++) {
        final labels = tioOrderedWeekdayLabels(
          firstDayOfWeek: start,
          localeName: 'en_US',
        );
        expect(labels, hasLength(DateTime.daysPerWeek));
        expect(labels.toSet(), monday.toSet(),
            reason: 'start $start must be a rotation, not a different week');
      }
    });
  });

  group('tioWeekdayName', () {
    test('names every day from the locale rather than a hard-coded table', () {
      expect(
        [
          for (var day = DateTime.monday; day <= DateTime.sunday; day++)
            tioWeekdayName(day, localeName: 'en_US'),
        ],
        <String>[
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday',
        ],
      );
    });

    test('the name and the abbreviation describe the same day', () {
      for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
        final abbreviation = tioOrderedWeekdayLabels(
          firstDayOfWeek: day,
          localeName: 'en_US',
        ).first;
        expect(
          tioWeekdayName(day, localeName: 'en_US').toUpperCase(),
          startsWith(abbreviation),
          reason: 'day $day disagrees between header and label',
        );
      }
    });
  });
}

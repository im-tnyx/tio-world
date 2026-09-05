import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  test('Monday is the bounded default and resolves to DateTime.monday', () {
    const preferences = CalendarPreferences();

    expect(preferences.firstDayOfWeek, FirstDayOfWeekPreference.monday);
    expect(preferences.resolvedFirstDayOfWeek, DateTime.monday);
    expect(
      FirstDayOfWeekPreference.monday.storageValue,
      'monday',
    );
    expect(
      FirstDayOfWeekPreference.sunday.storageValue,
      'sunday',
    );
  });

  test('Sunday resolves to DateTime.sunday without a display label in storage',
      () {
    const preferences = CalendarPreferences(
      firstDayOfWeek: FirstDayOfWeekPreference.sunday,
    );

    expect(preferences.resolvedFirstDayOfWeek, DateTime.sunday);
    expect(
      FirstDayOfWeekPreference.fromStorageValue('Sunday'),
      isNull,
    );
    expect(
      FirstDayOfWeekPreference.fromStorageValue('automatic'),
      isNull,
    );
  });

  test('copyWith changes only the selected calendar preference', () {
    const monday = CalendarPreferences();

    expect(
      monday.copyWith(firstDayOfWeek: FirstDayOfWeekPreference.sunday),
      const CalendarPreferences(
        firstDayOfWeek: FirstDayOfWeekPreference.sunday,
      ),
    );
    expect(monday, const CalendarPreferences());
  });
}

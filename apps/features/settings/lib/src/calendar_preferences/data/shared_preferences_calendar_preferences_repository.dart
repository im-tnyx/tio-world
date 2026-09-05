import 'package:shared_preferences/shared_preferences.dart';

import '../domain/calendar_preferences.dart';

/// Device-local owner for the app-global First day of week preference.
///
/// Local rather than account-synced for the same reason as Default Glass Size
/// (ADR-0009): a display convention is not health or account data, and syncing
/// it would add a table, RLS and a migration for one word.
final class SharedPreferencesCalendarPreferencesRepository
    implements CalendarPreferencesRepository {
  SharedPreferencesCalendarPreferencesRepository({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'calendar_first_day_of_week';

  final SharedPreferencesAsync _preferences;

  @override
  Future<CalendarPreferences> read() async {
    String? value;
    try {
      value = await _preferences.getString(storageKey);
    } on TypeError {
      // An older build could have written another type under this key.
      await _preferences.remove(storageKey);
      return const CalendarPreferences();
    }
    if (value == null) return const CalendarPreferences();

    final parsed = FirstDayOfWeekPreference.fromStorageValue(value);
    if (parsed == null) {
      // A value this build cannot mean is not a week start. Drop it rather
      // than laying the calendar out from a guess.
      await _preferences.remove(storageKey);
      return const CalendarPreferences();
    }

    return CalendarPreferences(firstDayOfWeek: parsed);
  }

  @override
  Future<void> write(CalendarPreferences preferences) =>
      _preferences.setString(
        storageKey,
        preferences.firstDayOfWeek.storageValue,
      );

  @override
  Future<void> clear() => _preferences.remove(storageKey);
}

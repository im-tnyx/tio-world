/// The week start every calendar surface in the app lays out from.
///
/// One app-global value, owned by Settings and consumed by Meal Diary today and
/// by Workout, Meal Plan and Progress later. A feature may choose its own
/// selected date and its own `minDate`/`maxDate`, but never its own week start:
/// a `nutritionFirstDayOfWeek` beside a `workoutFirstDayOfWeek` is exactly the
/// split this owner exists to prevent.
///
/// Every day of the week is offered. Monday, Sunday and Saturday cover most
/// conventions in use, and the remaining four are offered because a reader may
/// simply prefer one and the calendar's week arithmetic already supports any
/// start day.
///
/// This is the reader's preferred calendar week boundary and nothing else. A
/// feature whose own cycle begins mid-week — a training block, a meal plan —
/// is a separate domain concept and must not drive this value.
///
/// There is no `automatic`. The reusable calendar keeps a separate nullable
/// locale fallback for a caller that supplies nothing; that is a library
/// default, not this preference, and it is never persisted here.
///
/// Declared Monday first so the option list reads Monday through Sunday.
enum FirstDayOfWeekPreference {
  monday('monday', DateTime.monday),
  tuesday('tuesday', DateTime.tuesday),
  wednesday('wednesday', DateTime.wednesday),
  thursday('thursday', DateTime.thursday),
  friday('friday', DateTime.friday),
  saturday('saturday', DateTime.saturday),
  sunday('sunday', DateTime.sunday);

  const FirstDayOfWeekPreference(this.storageValue, this.weekday);

  /// The stable machine value written to storage.
  ///
  /// Deliberately not a display string: `Monday (default)` is what a reader
  /// sees, and putting it here would make a copy change a storage migration.
  /// Display names come from the locale in presentation, never from here.
  final String storageValue;

  /// The resolved `DateTime.monday`..`DateTime.sunday` value consumers read.
  final int weekday;

  static FirstDayOfWeekPreference? fromStorageValue(String? value) {
    for (final preference in values) {
      if (preference.storageValue == value) return preference;
    }
    return null;
  }
}

/// The Settings-owned Calendar Preferences family.
///
/// It holds one member today. It is a class rather than a bare enum so a second
/// calendar preference can join it without every consumer changing shape.
class CalendarPreferences {
  const CalendarPreferences({this.firstDayOfWeek = defaultFirstDayOfWeek});

  static const defaultFirstDayOfWeek = FirstDayOfWeekPreference.monday;

  final FirstDayOfWeekPreference firstDayOfWeek;

  /// What a calendar consumer is handed: an already-resolved week start.
  ///
  /// Today it resolves to the saved value itself. The indirection stays
  /// because the saved preference and the effective value are different
  /// questions, and a future `automatic` would answer the second one
  /// differently.
  int get resolvedFirstDayOfWeek => firstDayOfWeek.weekday;

  CalendarPreferences copyWith({FirstDayOfWeekPreference? firstDayOfWeek}) {
    return CalendarPreferences(
      firstDayOfWeek: firstDayOfWeek ?? this.firstDayOfWeek,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarPreferences && firstDayOfWeek == other.firstDayOfWeek;

  @override
  int get hashCode => firstDayOfWeek.hashCode;

  @override
  String toString() => 'CalendarPreferences(${firstDayOfWeek.storageValue})';
}

abstract interface class CalendarPreferencesRepository {
  Future<CalendarPreferences> read();

  /// Persists the choice on this device.
  Future<void> write(CalendarPreferences preferences);

  /// Removes the local value. The effective week start then reads as Monday.
  Future<void> clear();
}

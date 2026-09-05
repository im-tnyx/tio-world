/// The week start every calendar surface in the app lays out from.
///
/// One app-global value, owned by Settings and consumed by Meal Diary today and
/// by Workout, Meal Plan and Progress later. A feature may choose its own
/// selected date and its own `minDate`/`maxDate`, but never its own week start:
/// a `nutritionFirstDayOfWeek` beside a `workoutFirstDayOfWeek` is exactly the
/// split this owner exists to prevent.
///
/// V1 offers two choices and no `automatic`. The reusable calendar keeps a
/// separate nullable locale fallback for a caller that supplies nothing; that
/// is a library default, not this preference, and it is never persisted here.
enum FirstDayOfWeekPreference {
  monday('monday', DateTime.monday),
  sunday('sunday', DateTime.sunday);

  const FirstDayOfWeekPreference(this.storageValue, this.weekday);

  /// The stable machine value written to storage.
  ///
  /// Deliberately not a display string: `Monday (default)` is what a reader
  /// sees, and putting it here would make a copy change a storage migration.
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
  /// V1 resolves to the saved value itself. The indirection stays because the
  /// saved preference and the effective value are different questions, and a
  /// future `automatic` would answer the second one differently.
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

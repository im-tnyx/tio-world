/// Account-synced Settings preference, independent of Water Goal and display units.
/// Future hydration logging consumes this value without owning another copy.
class HydrationPreferences {
  const HydrationPreferences({this.defaultGlassSizeMl});

  static const presetsMl = [200, 250, 300, 350, 500];
  static const minimumMl = 50;
  static const maximumMl = 2000;
  static const incrementMl = 10;

  /// Null means explicitly unset, never an implicit 250 ml default.
  final int? defaultGlassSizeMl;

  static bool isValidGlassSize(int? value) =>
      value == null ||
      (value >= minimumMl && value <= maximumMl && value % incrementMl == 0);

  void validate() {
    if (!isValidGlassSize(defaultGlassSizeMl)) {
      throw ArgumentError.value(defaultGlassSizeMl, 'defaultGlassSizeMl',
          'Expected null or 50–2000 ml in increments of 10 ml.');
    }
  }

  @override
  bool operator ==(Object other) =>
      other is HydrationPreferences &&
      defaultGlassSizeMl == other.defaultGlassSizeMl;

  @override
  int get hashCode => defaultGlassSizeMl.hashCode;
}

abstract interface class HydrationPreferencesRepository {
  /// No row (or no signed-in user) is unset. Read failures must not become null.
  Future<HydrationPreferences?> read();

  /// Persists canonical ml only. A null field is an intentional clear.
  Future<void> upsert(HydrationPreferences preferences);
}

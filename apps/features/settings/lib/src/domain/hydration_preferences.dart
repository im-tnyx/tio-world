/// Device-local Settings preference, independent of Water Goal and display units.
///
/// It supplies a future hydration logger's default amount without becoming
/// hydration history, a target, or account-synced health data.
class HydrationPreferences {
  const HydrationPreferences({
    this.defaultGlassSizeMl = defaultGlassSizeMlDefault,
  });

  static const defaultGlassSizeMlDefault = 250;
  static const presetsMl = [200, 250, 300, 350, 500];
  static const minimumMl = 50;
  static const maximumMl = 2000;
  static const incrementMl = 10;

  final int defaultGlassSizeMl;

  static bool isValidGlassSize(int value) =>
      value >= minimumMl && value <= maximumMl && value % incrementMl == 0;

  void validate() {
    if (!isValidGlassSize(defaultGlassSizeMl)) {
      throw ArgumentError.value(defaultGlassSizeMl, 'defaultGlassSizeMl',
          'Expected 50–2000 ml in increments of 10 ml.');
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
  Future<HydrationPreferences> read();

  /// Persists canonical integer ml on this device.
  Future<void> write(HydrationPreferences preferences);

  /// Removes the local override. The effective value then reads as 250 ml.
  Future<void> clear();
}

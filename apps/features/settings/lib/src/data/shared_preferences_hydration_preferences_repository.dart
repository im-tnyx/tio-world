import 'package:shared_preferences/shared_preferences.dart';

import '../domain/hydration_preferences.dart';

/// Device-local owner for the Default Glass Size convenience preference.
final class SharedPreferencesHydrationPreferencesRepository
    implements HydrationPreferencesRepository {
  SharedPreferencesHydrationPreferencesRepository({
    SharedPreferencesAsync? preferences,
  }) : _preferences = preferences ?? SharedPreferencesAsync();

  static const storageKey = 'default_glass_size_ml';

  final SharedPreferencesAsync _preferences;

  @override
  Future<HydrationPreferences> read() async {
    int? value;
    try {
      value = await _preferences.getInt(storageKey);
    } on TypeError {
      await _preferences.remove(storageKey);
      return const HydrationPreferences();
    }
    if (value == null) return const HydrationPreferences();

    if (!HydrationPreferences.isValidGlassSize(value)) {
      await _preferences.remove(storageKey);
      return const HydrationPreferences();
    }

    return HydrationPreferences(defaultGlassSizeMl: value);
  }

  @override
  Future<void> write(HydrationPreferences preferences) async {
    preferences.validate();
    await _preferences.setInt(storageKey, preferences.defaultGlassSizeMl);
  }

  @override
  Future<void> clear() => _preferences.remove(storageKey);
}

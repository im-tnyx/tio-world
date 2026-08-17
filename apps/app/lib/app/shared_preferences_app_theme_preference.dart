import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_core/core.dart';

import 'app_theme_preference.dart';

class SharedPreferencesAppThemePreference implements AppThemePreference {
  SharedPreferencesAppThemePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'app_theme_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<void> clear() => _preferences.remove(_key);

  @override
  Future<TioThemeMode?> read() async {
    final value = await _preferences.getString(_key);
    return switch (value) {
      'system' => TioThemeMode.system,
      'light' => TioThemeMode.light,
      'dark' => TioThemeMode.dark,
      'oled' => TioThemeMode.oled,
      _ => null,
    };
  }

  @override
  Future<void> write(TioThemeMode mode) =>
      _preferences.setString(_key, _storageValue(mode));
}

String _storageValue(TioThemeMode mode) {
  return switch (mode) {
    TioThemeMode.system => 'system',
    TioThemeMode.light => 'light',
    TioThemeMode.dark => 'dark',
    TioThemeMode.oled => 'oled',
  };
}

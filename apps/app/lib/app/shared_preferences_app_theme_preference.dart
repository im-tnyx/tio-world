import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_core/core.dart';

import 'app_theme_preference.dart';

/// Device-local theme preference.
///
/// `app_theme_mode_v2` is canonical and always wins when present.
/// `app_theme_mode` is the legacy key. It keeps its OLD meanings
/// (`dark` = navy/slate, `oled` = pure-black) and is kept only as a temporary
/// downgrade/rollback mirror: it is migrated when V2 is absent, retained after
/// migration, and mirrored best-effort after every successful write. It never
/// decides behavior while V2 exists.
class SharedPreferencesAppThemePreference implements AppThemePreference {
  SharedPreferencesAppThemePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'app_theme_mode_v2';
  static const _legacyKey = 'app_theme_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<void> clear() async {
    // Legacy first, V2 last: a partial failure can never leave only the
    // legacy key behind, which the next read would migrate back.
    await _preferences.remove(_legacyKey);
    await _preferences.remove(_key);
  }

  @override
  Future<TioThemeMode?> read() async {
    final value = await _preferences.getString(_key);
    if (value != null) return _modeFromValue(value);

    final legacy = _modeFromLegacyValue(
      await _preferences.getString(_legacyKey),
    );
    if (legacy == null) return null;

    try {
      await _preferences.setString(_key, _storageValue(legacy));
    } catch (_) {
      // Keep the user's migrated selection for this session; the legacy key
      // is retained, so the migration is retried on the next read.
    }
    return legacy;
  }

  @override
  Future<void> write(TioThemeMode mode) async {
    await _preferences.setString(_key, _storageValue(mode));
    try {
      await _preferences.setString(_legacyKey, _legacyStorageValue(mode));
    } catch (_) {
      // V2 is canonical and already saved; only rollback compatibility is
      // degraded.
    }
  }
}

TioThemeMode? _modeFromValue(String value) {
  return switch (value) {
    'system' => TioThemeMode.system,
    'light' => TioThemeMode.light,
    'dark' => TioThemeMode.dark,
    'tio_dark' => TioThemeMode.tioDark,
    _ => null,
  };
}

TioThemeMode? _modeFromLegacyValue(String? value) {
  return switch (value) {
    'system' => TioThemeMode.system,
    'light' => TioThemeMode.light,
    'dark' => TioThemeMode.tioDark,
    'oled' => TioThemeMode.dark,
    _ => null,
  };
}

String _storageValue(TioThemeMode mode) {
  return switch (mode) {
    TioThemeMode.system => 'system',
    TioThemeMode.light => 'light',
    TioThemeMode.dark => 'dark',
    TioThemeMode.tioDark => 'tio_dark',
  };
}

String _legacyStorageValue(TioThemeMode mode) {
  return switch (mode) {
    TioThemeMode.system => 'system',
    TioThemeMode.light => 'light',
    TioThemeMode.dark => 'oled',
    TioThemeMode.tioDark => 'dark',
  };
}

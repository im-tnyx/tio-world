import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_shared/shared.dart';

/// Device-local staging for App Mode selected before authentication.
///
/// This is deliberately separate from the confirmed `app_mode` preference so
/// the Get Started journey can survive a relaunch without mutating an existing
/// signed-in account's current mode.
class PendingAppModePreference {
  PendingAppModePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'pending_app_mode';

  final SharedPreferencesAsync _preferences;

  Future<AppMode?> read() async {
    final value = await _preferences.getString(_key);
    return AppMode.fromStorageValue(value);
  }

  Future<void> write(AppMode mode) =>
      _preferences.setString(_key, mode.storageValue);

  Future<void> clear() => _preferences.remove(_key);
}

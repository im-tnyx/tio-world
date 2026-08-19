import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_shared/shared.dart';

/// Device-local staging for App Mode selected before authentication.
///
/// This is deliberately separate from the confirmed `app_mode` preference so
/// the Get Started journey can survive a relaunch without mutating an existing
/// signed-in account's current mode.
class PendingAppModePreference {
  PendingAppModePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences;

  static const _key = 'pending_app_mode';

  SharedPreferencesAsync? _preferences;
  AppMode? _memoryFallback;

  SharedPreferencesAsync _store() {
    return _preferences ??= SharedPreferencesAsync();
  }

  Future<AppMode?> read() async {
    try {
      final value = await _store().getString(_key);
      return AppMode.fromStorageValue(value) ?? _memoryFallback;
    } catch (_) {
      return _memoryFallback;
    }
  }

  Future<void> write(AppMode mode) async {
    _memoryFallback = mode;
    try {
      await _store().setString(_key, mode.storageValue);
    } catch (_) {
      // Keep the process-local fallback. Production uses the registered
      // SharedPreferences platform; tests/platform bootstrap failures remain safe.
    }
  }

  Future<void> clear() async {
    _memoryFallback = null;
    try {
      await _store().remove(_key);
    } catch (_) {
      // The process-local fallback is already cleared.
    }
  }
}

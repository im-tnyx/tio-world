import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_shared/shared.dart';

class SharedPreferencesAppModePreference implements AppModePreference {
  SharedPreferencesAppModePreference({SharedPreferencesAsync? preferences})
      : _preferences = preferences ?? SharedPreferencesAsync();

  static const _key = 'app_mode';

  final SharedPreferencesAsync _preferences;

  @override
  Future<void> clear() => _preferences.remove(_key);

  @override
  Future<AppMode?> read() async {
    final value = await _preferences.getString(_key);
    return AppMode.fromStorageValue(value);
  }

  @override
  Future<void> write(AppMode mode) =>
      _preferences.setString(_key, mode.storageValue);
}

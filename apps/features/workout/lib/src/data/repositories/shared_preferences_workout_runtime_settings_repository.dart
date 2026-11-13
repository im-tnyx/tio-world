import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/repositories/workout_runtime_settings_repository.dart';

/// Owner-scoped, device-local storage for Workout runtime preferences.
final class SharedPreferencesWorkoutRuntimeSettingsRepository
    implements WorkoutRuntimeSettingsRepository {
  SharedPreferencesWorkoutRuntimeSettingsRepository({
    required String ownerId,
    SharedPreferencesAsync? preferences,
  })  : _ownerId = ownerId.trim(),
        _preferences = preferences {
    if (_ownerId.isEmpty) {
      throw ArgumentError.value(ownerId, 'ownerId', 'Must not be empty.');
    }
  }

  static const _keyPrefix = 'workout_default_rest_timer_seconds_v1_';
  static const _vibrationKeyPrefix = 'workout_rest_timer_vibration_enabled_v1_';
  static const _rpeKeyPrefix = 'workout_rpe_tracking_enabled_v1_';

  static String vibrationStorageKeyFor(String ownerId) =>
      '$_vibrationKeyPrefix${ownerId.trim()}';

  static String storageKeyFor(String ownerId) => '$_keyPrefix${ownerId.trim()}';

  static String rpeStorageKeyFor(String ownerId) =>
      '$_rpeKeyPrefix${ownerId.trim()}';

  final String _ownerId;
  SharedPreferencesAsync? _preferences;

  String get _storageKey => storageKeyFor(_ownerId);
  String get _vibrationStorageKey => vibrationStorageKeyFor(_ownerId);
  String get _rpeStorageKey => rpeStorageKeyFor(_ownerId);

  SharedPreferencesAsync get _store =>
      _preferences ??= SharedPreferencesAsync();

  @override
  Future<int?> readDefaultRestSeconds() async {
    int? seconds;
    try {
      seconds = await _store.getInt(_storageKey);
    } on TypeError {
      await _store.remove(_storageKey);
      return null;
    }
    if (seconds == null) return null;
    if (!_isSupported(seconds)) {
      await _store.remove(_storageKey);
      return null;
    }
    return seconds;
  }

  @override
  Future<void> writeDefaultRestSeconds(int seconds) async {
    if (!_isSupported(seconds)) {
      throw ArgumentError.value(seconds, 'seconds', 'Unsupported rest duration.');
    }
    await _store.setInt(_storageKey, seconds);
  }

  @override
  Future<void> clearDefaultRestSeconds() => _store.remove(_storageKey);

  @override
  Future<bool> readRestTimerVibrationEnabled() async {
    try {
      return await _store.getBool(_vibrationStorageKey) ?? false;
    } on TypeError {
      await _store.remove(_vibrationStorageKey);
      return false;
    }
  }

  @override
  Future<void> writeRestTimerVibrationEnabled(bool enabled) =>
      _store.setBool(_vibrationStorageKey, enabled);

  @override
  Future<bool> readRpeTrackingEnabled() async {
    try {
      return await _store.getBool(_rpeStorageKey) ?? false;
    } on TypeError {
      await _store.remove(_rpeStorageKey);
      return false;
    }
  }

  @override
  Future<void> writeRpeTrackingEnabled(bool enabled) =>
      _store.setBool(_rpeStorageKey, enabled);

  static bool _isSupported(int seconds) =>
      seconds == 0 ||
      (seconds >= 5 && seconds <= 600 && seconds % 5 == 0);
}

import 'package:flutter/foundation.dart';

import '../../domain/models/routine_rest_timer_preset.dart';
import '../../domain/repositories/workout_runtime_settings_repository.dart';

/// Holds the current device-local Workout settings for one owner-scoped
/// provider lifetime. Null means unset; zero means explicitly OFF.
final class WorkoutRuntimeSettingsController extends ChangeNotifier {
  WorkoutRuntimeSettingsController({
    required WorkoutRuntimeSettingsRepository repository,
  }) : _repository = repository;

  final WorkoutRuntimeSettingsRepository _repository;
  Future<void>? _loadFuture;
  int? _savedDefaultRestSeconds;
  bool _isLoaded = false;
  bool _isLoading = false;
  bool _isSaving = false;
  Object? _error;

  // Optional haptic preference must never block Default Rest or Add Exercise.
  Future<void>? _vibrationLoadFuture;
  bool _isVibrationLoaded = false;
  bool _isVibrationLoading = false;
  bool _isVibrationSaving = false;
  bool _restTimerVibrationEnabled = false;
  Object? _vibrationError;

  // RPE UI preference is independent of Rest Timer and draft Save.
  Future<void>? _rpeLoadFuture;
  bool _isRpeLoaded = false;
  bool _isRpeLoading = false;
  bool _isRpeSaving = false;
  bool _rpeTrackingEnabled = false;
  Object? _rpeError;

  // Superset scrolling is opt-in and independent from other device settings.
  Future<void>? _smartSupersetScrollingLoadFuture;
  bool _isSmartSupersetScrollingLoaded = false;
  bool _isSmartSupersetScrollingLoading = false;
  bool _isSmartSupersetScrollingSaving = false;
  bool _smartSupersetScrollingEnabled = false;
  Object? _smartSupersetScrollingError;

  bool get isRpeLoading => _isRpeLoading;
  bool get isRpeSaving => _isRpeSaving;
  bool get isRpeReady => _isRpeLoaded && _rpeError == null;
  bool get rpeTrackingEnabled => isRpeReady && _rpeTrackingEnabled;
  Object? get rpeError => _rpeError;

  bool get isSmartSupersetScrollingLoading =>
      _isSmartSupersetScrollingLoading;
  bool get isSmartSupersetScrollingSaving => _isSmartSupersetScrollingSaving;
  bool get isSmartSupersetScrollingReady =>
      _isSmartSupersetScrollingLoaded && _smartSupersetScrollingError == null;
  bool get smartSupersetScrollingEnabled =>
      isSmartSupersetScrollingReady && _smartSupersetScrollingEnabled;
  Object? get smartSupersetScrollingError => _smartSupersetScrollingError;

  Future<void> loadSmartSupersetScrolling() {
    if (_isSmartSupersetScrollingLoaded) return Future<void>.value();
    return _smartSupersetScrollingLoadFuture ??=
        _loadSmartSupersetScrolling();
  }

  Future<void> _loadSmartSupersetScrolling() async {
    _isSmartSupersetScrollingLoading = true;
    _smartSupersetScrollingError = null;
    notifyListeners();
    try {
      _smartSupersetScrollingEnabled =
          await _repository.readSmartSupersetScrollingEnabled();
      _isSmartSupersetScrollingLoaded = true;
    } catch (error) {
      _smartSupersetScrollingError = error;
      _smartSupersetScrollingEnabled = false;
    } finally {
      _isSmartSupersetScrollingLoading = false;
      _smartSupersetScrollingLoadFuture = null;
      notifyListeners();
    }
  }

  Future<void> setSmartSupersetScrollingEnabled(bool enabled) async {
    await loadSmartSupersetScrolling();
    if (!isSmartSupersetScrollingReady) {
      throw StateError('Smart Superset Scrolling preference is unavailable.');
    }
    _isSmartSupersetScrollingSaving = true;
    notifyListeners();
    try {
      await _repository.writeSmartSupersetScrollingEnabled(enabled);
      _smartSupersetScrollingEnabled = enabled;
    } finally {
      _isSmartSupersetScrollingSaving = false;
      notifyListeners();
    }
  }

  Future<void> loadRpeTracking() {
    if (_isRpeLoaded) return Future<void>.value();
    return _rpeLoadFuture ??= _loadRpeTracking();
  }

  Future<void> _loadRpeTracking() async {
    _isRpeLoading = true;
    _rpeError = null;
    notifyListeners();
    try {
      _rpeTrackingEnabled = await _repository.readRpeTrackingEnabled();
      _isRpeLoaded = true;
    } catch (error) {
      // Fail closed; never block Default Rest, Add Exercise or Save.
      _rpeError = error;
      _rpeTrackingEnabled = false;
    } finally {
      _isRpeLoading = false;
      _rpeLoadFuture = null;
      notifyListeners();
    }
  }

  Future<void> setRpeTrackingEnabled(bool enabled) async {
    await loadRpeTracking();
    if (!isRpeReady) {
      throw StateError('RPE Tracking preference is unavailable.');
    }
    _isRpeSaving = true;
    notifyListeners();
    try {
      await _repository.writeRpeTrackingEnabled(enabled);
      _rpeTrackingEnabled = enabled;
    } finally {
      _isRpeSaving = false;
      notifyListeners();
    }
  }

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isReady => _isLoaded && _error == null;
  Object? get error => _error;

  bool get isVibrationLoading => _isVibrationLoading;
  bool get isVibrationSaving => _isVibrationSaving;
  bool get isVibrationReady => _isVibrationLoaded && _vibrationError == null;
  bool get restTimerVibrationEnabled =>
      isVibrationReady && _restTimerVibrationEnabled;
  Object? get vibrationError => _vibrationError;

  Future<void> loadRestTimerVibration() {
    if (_isVibrationLoaded) return Future<void>.value();
    return _vibrationLoadFuture ??= _loadRestTimerVibration();
  }

  Future<void> _loadRestTimerVibration() async {
    _isVibrationLoading = true;
    _vibrationError = null;
    notifyListeners();
    try {
      _restTimerVibrationEnabled =
          await _repository.readRestTimerVibrationEnabled();
      _isVibrationLoaded = true;
    } catch (error) {
      // Optional feedback fails closed; never block Workout or default rest.
      _vibrationError = error;
      _restTimerVibrationEnabled = false;
    } finally {
      _isVibrationLoading = false;
      _vibrationLoadFuture = null;
      notifyListeners();
    }
  }

  Future<void> setRestTimerVibrationEnabled(bool enabled) async {
    await loadRestTimerVibration();
    if (!isVibrationReady) {
      throw StateError('Rest Timer Vibration preference is unavailable.');
    }
    _isVibrationSaving = true;
    notifyListeners();
    try {
      await _repository.writeRestTimerVibrationEnabled(enabled);
      _restTimerVibrationEnabled = enabled;
    } finally {
      _isVibrationSaving = false;
      notifyListeners();
    }
  }

  /// Null is the unset state; zero is an explicit OFF selection.
  int? get savedDefaultRestSeconds => _savedDefaultRestSeconds;

  /// Unset preferences resolve to OFF for newly added Exercises.
  int get effectiveDefaultRestSeconds => _savedDefaultRestSeconds ?? 0;

  RoutineRestTimerPreset get defaultRestPreset =>
      RoutineRestTimerPreset(normalRestSeconds: effectiveDefaultRestSeconds);

  String get defaultRestLabel => effectiveDefaultRestSeconds == 0
      ? 'OFF'
      : RoutineRestTimerFormatter.formatSeconds(effectiveDefaultRestSeconds);

  Future<void> load() {
    if (_isLoaded) return Future<void>.value();
    return _loadFuture ??= _load();
  }

  Future<void> _load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _savedDefaultRestSeconds = await _repository.readDefaultRestSeconds();
      _isLoaded = true;
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      // A failed read must not permanently pin a completed load future.
      // A later Add Exercise attempt or Settings Retry can start a fresh read.
      _loadFuture = null;
      notifyListeners();
    }
  }

  /// Stores an explicit selection. Passing null from the wheel means OFF and
  /// is persisted as zero, leaving null reserved for the never-set state.
  Future<void> setDefaultRestSeconds(int? seconds) async {
    await load();
    if (!isReady) throw StateError('Workout settings are unavailable.');
    if (seconds != null && !_isSupported(seconds)) {
      throw ArgumentError.value(seconds, 'seconds', 'Unsupported rest duration.');
    }
    final valueToSave = seconds ?? 0;
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.writeDefaultRestSeconds(valueToSave);
      _savedDefaultRestSeconds = valueToSave;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> clearDefaultRestSeconds() async {
    await load();
    if (!isReady) throw StateError('Workout settings are unavailable.');
    _isSaving = true;
    notifyListeners();
    try {
      await _repository.clearDefaultRestSeconds();
      _savedDefaultRestSeconds = null;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  static bool _isSupported(int seconds) =>
      seconds == 0 || (seconds >= 5 && seconds <= 600 && seconds % 5 == 0);
}

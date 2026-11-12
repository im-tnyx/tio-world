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

  bool get isLoaded => _isLoaded;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isReady => _isLoaded && _error == null;
  Object? get error => _error;

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

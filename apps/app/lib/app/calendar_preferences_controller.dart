import 'package:flutter/foundation.dart';
import 'package:tio_feature_settings/settings.dart';

/// The one app-global holder of the effective week start.
///
/// Deliberately shaped like [AppThemeController]: load once at startup, apply
/// optimistically on select, persist behind a queue so two quick taps cannot
/// land out of order, and keep the last failure visible rather than silently
/// showing a value that was never written.
class CalendarPreferencesController extends ChangeNotifier {
  CalendarPreferencesController(this._repository);

  final CalendarPreferencesRepository _repository;

  CalendarPreferences _preferences = const CalendarPreferences();
  bool _isLoaded = false;
  bool _isSaving = false;
  Object? _lastError;
  Future<void> _selectionQueue = Future<void>.value();
  int _pendingSelections = 0;

  CalendarPreferences get preferences => _preferences;
  FirstDayOfWeekPreference get firstDayOfWeek => _preferences.firstDayOfWeek;

  /// The already-resolved `DateTime.monday`..`DateTime.sunday` value handed to
  /// every calendar. Consumers never see the saved preference itself.
  int get resolvedFirstDayOfWeek => _preferences.resolvedFirstDayOfWeek;

  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  Object? get lastError => _lastError;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      _preferences = await _repository.read();
      _lastError = null;
    } catch (error) {
      // Unreadable storage is not a reason to refuse to draw a calendar.
      _preferences = const CalendarPreferences();
      _lastError = error;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> select(FirstDayOfWeekPreference preference) async {
    _pendingSelections++;
    if (!_isSaving) {
      _isSaving = true;
      _lastError = null;
      notifyListeners();
    }

    final operation = _selectionQueue.then<void>(
      (_) => _persistSelection(preference),
      onError: (Object _, StackTrace __) => _persistSelection(preference),
    );
    _selectionQueue = operation;

    return operation.whenComplete(() {
      _pendingSelections--;
      _isSaving = _pendingSelections > 0;
      notifyListeners();
    });
  }

  Future<void> _persistSelection(FirstDayOfWeekPreference preference) async {
    _lastError = null;
    final next = _preferences.copyWith(firstDayOfWeek: preference);
    try {
      await _repository.write(next);
      _preferences = next;
    } catch (error) {
      _lastError = error;
      rethrow;
    }
  }

  Future<void> clear() async {
    await _repository.clear();
    _preferences = const CalendarPreferences();
    _lastError = null;
    notifyListeners();
  }
}

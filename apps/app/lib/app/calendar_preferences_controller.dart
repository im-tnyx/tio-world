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
  Object? _loadError;
  Object? _saveError;
  Future<void> _selectionQueue = Future<void>.value();
  int _pendingSelections = 0;

  CalendarPreferences get preferences => _preferences;
  FirstDayOfWeekPreference get firstDayOfWeek => _preferences.firstDayOfWeek;

  /// The already-resolved `DateTime.monday`..`DateTime.sunday` value handed to
  /// every calendar. Consumers never see the saved preference itself.
  int get resolvedFirstDayOfWeek => _preferences.resolvedFirstDayOfWeek;

  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;

  /// A storage-read problem retained for diagnostics. Calendar rendering still
  /// falls back to Monday, so this must never be presented as a save failure.
  Object? get loadError => _loadError;

  /// The most recent failed user-initiated write. The Settings route renders
  /// this as a retryable save error while keeping the prior effective value.
  Object? get saveError => _saveError;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      _preferences = await _repository.read();
      _loadError = null;
    } catch (error) {
      // Unreadable storage is not a reason to refuse to draw a calendar.
      _preferences = const CalendarPreferences();
      _loadError = error;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> select(FirstDayOfWeekPreference preference) async {
    _pendingSelections++;
    if (!_isSaving) {
      _isSaving = true;
      _saveError = null;
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
    _saveError = null;
    final previous = _preferences;
    final next = previous.copyWith(firstDayOfWeek: preference);

    if (next != previous) {
      // Immediate apply means the tap lands now, not when storage answers. A
      // slow or hung device-local write must not leave the chosen option
      // unchosen and Meal Diary still laid out from the old week start.
      _preferences = next;
      notifyListeners();
    }

    try {
      await _repository.write(next);
    } catch (error) {
      // Storage refused, so the screen stops claiming a value it does not
      // have. The retryable error is what the caller shows instead.
      _preferences = previous;
      _saveError = error;
      rethrow;
    }
  }

  Future<void> clear() async {
    await _repository.clear();
    _preferences = const CalendarPreferences();
    _loadError = null;
    _saveError = null;
    notifyListeners();
  }
}

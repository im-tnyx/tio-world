import 'package:flutter/foundation.dart';
import 'package:tio_feature_settings/settings.dart';

/// The one app-global holder of the effective week start.
///
/// Shaped like [AppThemeController]: load once at startup, apply optimistically
/// on select, persist behind a queue so two quick taps cannot land out of
/// order, and keep the last failure visible rather than silently showing a
/// value that was never written.
///
/// Publishing and persisting are deliberately separate. Every tap becomes the
/// effective value straight away, while the writes behind them stay serialised:
/// with seven options a reader can easily out-run a slow device-local store,
/// and holding the second tap until the first write answers would make the
/// screen lie about what is selected.
///
/// That split needs a way to tell a finished write whether it still speaks for
/// the user, which is what [_selectionRevision] is for. A write that lands
/// after a newer tap has been published is stale: its failure is not the
/// current failure and it may not roll anything back, because doing so would
/// undo an intent expressed after it left.
class CalendarPreferencesController extends ChangeNotifier {
  CalendarPreferencesController(this._repository);

  final CalendarPreferencesRepository _repository;

  CalendarPreferences _preferences = const CalendarPreferences();

  /// The last value storage is known to hold. Rollback returns here rather than
  /// to whatever was on screen before the failed tap: after Monday → Tuesday →
  /// Wednesday with Tuesday's write already failed, the screen must fall back
  /// to Monday, which is what the device actually has.
  CalendarPreferences _persisted = const CalendarPreferences();

  /// Bumped by every selection. A write carries the revision it was made for.
  int _selectionRevision = 0;

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
      _persisted = _preferences;
      _loadError = null;
    } catch (error) {
      // Unreadable storage is not a reason to refuse to draw a calendar.
      _preferences = const CalendarPreferences();
      _persisted = _preferences;
      _loadError = error;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> select(FirstDayOfWeekPreference preference) async {
    final revision = ++_selectionRevision;
    final next = _preferences.copyWith(firstDayOfWeek: preference);

    // Published here, outside the queue. Immediate apply is about the tap, not
    // about how long an older write is taking to answer, so a second choice
    // made while the first is still in flight lands on screen at once.
    _preferences = next;
    _saveError = null;
    _pendingSelections++;
    _isSaving = true;
    notifyListeners();

    // The write itself stays in line, so a slow earlier write cannot finish
    // last and leave the device holding a value the user has already replaced.
    final operation = _selectionQueue.then<void>(
      (_) => _persistSelection(next, revision),
      onError: (Object _, StackTrace __) => _persistSelection(next, revision),
    );
    _selectionQueue = operation;

    return operation.whenComplete(() {
      _pendingSelections--;
      _isSaving = _pendingSelections > 0;
      notifyListeners();
    });
  }

  Future<void> _persistSelection(
    CalendarPreferences next,
    int revision,
  ) async {
    try {
      await _repository.write(next);
      _persisted = next;
    } catch (error) {
      if (revision != _selectionRevision) {
        // A newer tap already replaced this one on screen. Rolling back or
        // reporting a failure here would speak for a choice the user has
        // moved on from; the newer write is the one that answers for them.
        return;
      }
      // Storage refused the current choice, so the screen stops claiming a
      // value the device does not have. The retryable error is what the
      // caller shows instead.
      _preferences = _persisted;
      _saveError = error;
      rethrow;
    }
  }

  Future<void> clear() async {
    await _repository.clear();
    _preferences = const CalendarPreferences();
    _persisted = _preferences;
    _selectionRevision++;
    _loadError = null;
    _saveError = null;
    notifyListeners();
  }
}

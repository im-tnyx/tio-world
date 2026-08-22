import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

class AppModeController extends ChangeNotifier {
  AppModeController(this._preference);

  final AppModePreference _preference;

  AppMode? _selectedMode;
  List<AppDestination>? _activeDestinations;
  bool _isLoaded = false;
  bool _isSaving = false;
  Object? _lastError;
  Future<void> _selectionQueue = Future<void>.value();
  int _pendingSelections = 0;

  AppMode? get selectedMode => _selectedMode;
  List<AppDestination>? get activeDestinations => _activeDestinations;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  Object? get lastError => _lastError;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      _selectedMode = await _preference.read();
      _activeDestinations = _selectedMode?.guidedDestinations;
      _lastError = null;
    } catch (error) {
      _selectedMode = null;
      _activeDestinations = null;
      _lastError = error;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> select(AppMode mode) async {
    _pendingSelections++;
    if (!_isSaving) {
      _isSaving = true;
      _lastError = null;
      notifyListeners();
    }

    final operation = _selectionQueue.then<void>(
      (_) => _persistSelection(mode),
      onError: (Object _, StackTrace __) => _persistSelection(mode),
    );
    _selectionQueue = operation;

    return operation.whenComplete(() {
      _pendingSelections--;
      _isSaving = _pendingSelections > 0;
      notifyListeners();
    });
  }

  Future<void> _persistSelection(AppMode mode) async {
    _lastError = null;
    try {
      await _preference.write(mode);
      _selectedMode = mode;
      _activeDestinations = mode.guidedDestinations;
    } catch (error) {
      _lastError = error;
      rethrow;
    }
  }

  /// Publishes an already-committed canonical App Preferences update.
  ///
  /// This is used by authenticated Settings after the remote repository has
  /// successfully accepted [update]. Local preference persistence is only a
  /// best-effort cache at this point, so a cache failure cannot roll back or
  /// hide valid canonical account truth.
  Future<void> applyCanonicalUpdate(AppPreferencesUpdate update) async {
    await _publishCanonical(
      mode: update.appMode,
      destinations: update.activeTabs,
    );
  }

  /// Publishes already-validated canonical authenticated preferences.
  ///
  /// Remote state is authoritative here. The legacy [AppModePreference] is only
  /// refreshed as a best-effort cache; a local cache write failure must not
  /// override valid canonical account state.
  Future<void> restoreCanonical(AppPreferencesState preferences) async {
    if (!preferences.isPresent) {
      throw ArgumentError.value(
        preferences,
        'preferences',
        'Canonical preferences must be present before restore.',
      );
    }

    final mode = preferences.appMode;
    if (mode == null) {
      throw StateError(
        'Canonical App preferences are present without an App Mode.',
      );
    }

    await _publishCanonical(
      mode: mode,
      destinations: preferences.activeTabs ?? mode.guidedDestinations,
    );
  }

  Future<void> _publishCanonical({
    required AppMode mode,
    required List<AppDestination> destinations,
  }) async {
    final effectiveDestinations =
        List<AppDestination>.unmodifiable(destinations);

    Object? cacheError;
    try {
      await _preference.write(mode);
    } catch (error) {
      cacheError = error;
    }

    _selectedMode = mode;
    _activeDestinations = effectiveDestinations;
    _lastError = cacheError;
    _isLoaded = true;
    notifyListeners();
  }

  /// Clears device-local semantic mode when a completed authenticated account
  /// has no canonical preference row.
  ///
  /// The cache clear is best effort because local storage is not authenticated
  /// authority. Publishing null prevents another account's stale device cache
  /// from becoming the current user's semantic mode.
  Future<void> restoreMissingCanonical() async {
    Object? cacheError;
    try {
      await _preference.clear();
    } catch (error) {
      cacheError = error;
    }

    _selectedMode = null;
    _activeDestinations = null;
    _lastError = cacheError;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> clear() async {
    await _preference.clear();
    _selectedMode = null;
    _activeDestinations = null;
    _lastError = null;
    notifyListeners();
  }
}

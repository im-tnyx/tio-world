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
  AppPreferencesRepository? _authenticatedWriteRepository;
  bool _authenticatedWriteRequired = false;

  AppMode? get selectedMode => _selectedMode;
  List<AppDestination>? get activeDestinations => _activeDestinations;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  Object? get lastError => _lastError;

  /// Configures App Mode writes for the current session lifecycle.
  ///
  /// When [requireCanonical] is true, selection must commit through
  /// [repository] before runtime publication. A missing repository then fails
  /// closed instead of falling back to local-only persistence. Pre-auth and
  /// onboarding flows disable this requirement so local staging remains valid.
  void setAuthenticatedWriteRepository(
    AppPreferencesRepository? repository, {
    bool requireCanonical = true,
  }) {
    _authenticatedWriteRepository = repository;
    _authenticatedWriteRequired = requireCanonical;
  }

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

    if (_authenticatedWriteRequired) {
      final canonicalRepository = _authenticatedWriteRepository;
      if (canonicalRepository == null) {
        final error = StateError(
          'Canonical App preferences are unavailable for this authenticated update.',
        );
        _lastError = error;
        throw error;
      }

      final update = AppPreferencesUpdate.guided(mode);
      try {
        await canonicalRepository.upsert(update);
        await _publishCanonical(
          mode: update.appMode,
          destinations: update.activeTabs,
        );
      } catch (error) {
        _lastError = error;
        rethrow;
      }
      return;
    }

    try {
      await _preference.write(mode);
      _selectedMode = mode;
      _activeDestinations = mode.guidedDestinations;
    } catch (error) {
      _lastError = error;
      rethrow;
    }
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

import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

class AppModeController extends ChangeNotifier {
  AppModeController(this._preference);

  final AppModePreference _preference;

  AppMode? _selectedMode;
  bool _isLoaded = false;
  bool _isSaving = false;
  Object? _lastError;

  AppMode? get selectedMode => _selectedMode;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  Object? get lastError => _lastError;

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      _selectedMode = await _preference.read();
      _lastError = null;
    } catch (error) {
      _selectedMode = null;
      _lastError = error;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> select(AppMode mode) async {
    if (_isSaving) return;

    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      await _preference.write(mode);
      _selectedMode = mode;
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> clear() async {
    await _preference.clear();
    _selectedMode = null;
    _lastError = null;
    notifyListeners();
  }
}

import 'package:flutter/foundation.dart';
import 'package:tio_shared/shared.dart';

class AppModeController extends ChangeNotifier {
  AppModeController(this._preference);

  final AppModePreference _preference;

  AppMode? _selectedMode;
  bool _isLoaded = false;
  bool _isSaving = false;
  Object? _lastError;
  Future<void> _selectionQueue = Future<void>.value();
  int _pendingSelections = 0;

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
    } catch (error) {
      _lastError = error;
      rethrow;
    }
  }

  Future<void> clear() async {
    await _preference.clear();
    _selectedMode = null;
    _lastError = null;
    notifyListeners();
  }
}

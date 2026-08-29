import 'package:flutter/foundation.dart';
import '../domain/hydration_preferences.dart';

/// Sheet-local draft. Disposing the sheet discards unsaved changes.
class HydrationPreferencesEditorController extends ChangeNotifier {
  HydrationPreferencesEditorController(HydrationPreferences initial) {
    _canonicalMl = initial.defaultGlassSizeMl;
    _adoptCanonical();
  }

  late int _canonicalMl;
  late int _draftMl;
  var _custom = false;
  var _customText = '';
  var _saving = false;
  var _disposed = false;
  String? _saveError;

  int get draftMl => _draftMl;
  bool get isCustom => _custom;
  String get customText => _customText;
  bool get isSaving => _saving;
  String? get saveError => _saveError;

  String? get validationError {
    if (!_custom) return null;
    final value = int.tryParse(_customText.trim());
    if (value == null ||
        !RegExp(r'^\d+$').hasMatch(_customText.trim()) ||
        !HydrationPreferences.isValidGlassSize(value)) {
      return 'Enter 50–2000 ml in increments of 10 ml.';
    }
    return null;
  }

  bool get isDirty => validationError != null || _draftMl != _canonicalMl;
  bool get canSave => !_saving && isDirty && validationError == null;

  void refresh(HydrationPreferences canonical) {
    final wasDirty = isDirty;
    _canonicalMl = canonical.defaultGlassSizeMl;
    if (!wasDirty && !_saving) _adoptCanonical();
    notifyListeners();
  }

  void _adoptCanonical() {
    _draftMl = _canonicalMl;
    _custom = !HydrationPreferences.presetsMl.contains(_draftMl);
    _customText = _draftMl.toString();
  }

  void selectPreset(int value) {
    if (_saving) return;
    if (!HydrationPreferences.presetsMl.contains(value)) {
      throw ArgumentError.value(value, 'value', 'Unknown Glass Size preset.');
    }
    _draftMl = value;
    _custom = false;
    _customText = value.toString();
    _changed();
  }

  void selectCustom() {
    if (_saving) return;
    _custom = true;
    _customText = _draftMl.toString();
    _changed();
  }

  void setCustomText(String text) {
    if (_saving) return;
    _custom = true;
    _customText = text;
    _draftMl = int.tryParse(text.trim()) ?? _canonicalMl;
    _changed();
  }

  void resetToDefault() {
    if (_saving) return;
    _draftMl = HydrationPreferences.defaultGlassSizeMlDefault;
    _customText = _draftMl.toString();
    _custom = false;
    _changed();
  }

  void _changed() {
    _saveError = null;
    notifyListeners();
  }

  Future<HydrationPreferences?> save(
    Future<void> Function(HydrationPreferences) persist,
  ) async {
    if (!canSave) return null;
    final value = HydrationPreferences(defaultGlassSizeMl: _draftMl);
    value.validate();
    _saving = true;
    _saveError = null;
    notifyListeners();
    try {
      await persist(value);
      if (_disposed) return null;
      _canonicalMl = value.defaultGlassSizeMl;
      return value;
    } catch (_) {
      if (!_disposed) {
        _saveError = 'Could not save Glass Size. Please try again.';
      }
      return null;
    } finally {
      if (!_disposed) {
        _saving = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

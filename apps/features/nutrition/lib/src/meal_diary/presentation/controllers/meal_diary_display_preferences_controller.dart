import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shared_preferences_meal_diary_display_preferences_repository.dart';
import '../../domain/models/meal_diary_display_preferences.dart';
import '../../domain/repositories/meal_diary_display_preferences_repository.dart';

/// Canonical runtime owner for Meal Diary display preferences.
///
/// The controller publishes a toggle immediately, then serializes device-local
/// writes so rapid changes cannot land out of order. A failed current write
/// rolls back to the last snapshot storage confirmed. Superseded failures do
/// not undo a newer user choice.
class MealDiaryDisplayPreferencesController extends ChangeNotifier {
  MealDiaryDisplayPreferencesController(
    MealDiaryDisplayPreferencesRepository repository,
  ) : _repository = repository;

  final MealDiaryDisplayPreferencesRepository _repository;

  MealDiaryDisplayPreferences _preferences =
      const MealDiaryDisplayPreferences();
  MealDiaryDisplayPreferences _persisted =
      const MealDiaryDisplayPreferences();

  Future<void>? _loadFuture;
  Future<void> _writeQueue = Future<void>.value();
  int _selectionRevision = 0;
  int _pendingWrites = 0;
  bool _isLoaded = false;
  bool _isSaving = false;
  Object? _loadError;
  Object? _saveError;

  MealDiaryDisplayPreferences get preferences => _preferences;
  bool get isLoaded => _isLoaded;
  bool get isSaving => _isSaving;
  Object? get loadError => _loadError;
  Object? get saveError => _saveError;

  Future<void> load() => _loadFuture ??= _load();

  Future<void> _load() async {
    try {
      _preferences = await _repository.read();
      _persisted = _preferences;
      _loadError = null;
    } catch (error) {
      // A device-local display preference must never block Meal Diary. Use the
      // product defaults and retain the error only for diagnostics/tests.
      _preferences = const MealDiaryDisplayPreferences();
      _persisted = _preferences;
      _loadError = error;
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setShowMealTimes(bool value) async {
    await load();
    await _select(_preferences.copyWith(showMealTimes: value));
  }

  Future<void> setMealNotesEnabled(bool value) async {
    await load();
    // Deliberately preserve showMealNotePreview. Disabling Meal Notes hides the
    // capability; it does not rewrite the reader's preview preference or any
    // stored MealLogEntry.note.
    await _select(_preferences.copyWith(mealNotesEnabled: value));
  }

  Future<void> setShowMealNotePreview(bool value) async {
    await load();
    if (!_preferences.mealNotesEnabled) return;
    await _select(_preferences.copyWith(showMealNotePreview: value));
  }

  Future<void> _select(MealDiaryDisplayPreferences next) {
    if (next == _preferences) return Future<void>.value();

    final revision = ++_selectionRevision;
    _preferences = next;
    _saveError = null;
    _pendingWrites++;
    _isSaving = true;
    notifyListeners();

    final operation = _writeQueue.then<void>(
      (_) => _persist(next, revision),
      onError: (Object _, StackTrace __) => _persist(next, revision),
    );
    _writeQueue = operation;

    return operation.whenComplete(() {
      _pendingWrites--;
      _isSaving = _pendingWrites > 0;
      notifyListeners();
    });
  }

  Future<void> _persist(
    MealDiaryDisplayPreferences next,
    int revision,
  ) async {
    try {
      await _repository.write(next);
      _persisted = next;
    } catch (error) {
      if (revision != _selectionRevision) {
        // A newer user intent is already visible and queued. This older failure
        // must not roll it back or surface as its failure.
        return;
      }
      _preferences = _persisted;
      _saveError = error;
      notifyListeners();
    }
  }
}

/// Feature-owned default composition for harnesses and tests that do not run
/// the production app bootstrap. Production preloads one controller at startup
/// and overrides this provider with that same instance.
final mealDiaryDisplayPreferencesRepositoryProvider =
    Provider<MealDiaryDisplayPreferencesRepository>(
  (ref) => SharedPreferencesMealDiaryDisplayPreferencesRepository(),
);

final mealDiaryDisplayPreferencesControllerProvider =
    ChangeNotifierProvider<MealDiaryDisplayPreferencesController>((ref) {
  final controller = MealDiaryDisplayPreferencesController(
    ref.watch(mealDiaryDisplayPreferencesRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  unawaited(controller.load());
  return controller;
});

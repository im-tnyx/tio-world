import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

void main() {
  group('MealDiaryDisplayPreferencesController', () {
    test('loads stored display preferences', () async {
      final controller = MealDiaryDisplayPreferencesController(
        _FakeRepository(
          value: const MealDiaryDisplayPreferences(
            showMealTimes: false,
            mealNotesEnabled: true,
            showMealNotePreview: true,
          ),
        ),
      );

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(
        controller.preferences,
        const MealDiaryDisplayPreferences(
          showMealTimes: false,
          mealNotesEnabled: true,
          showMealNotePreview: true,
        ),
      );
      expect(controller.loadError, isNull);
      expect(controller.saveError, isNull);
    });

    test('read failure falls back to product defaults', () async {
      final controller = MealDiaryDisplayPreferencesController(
        _FakeRepository(
          value: const MealDiaryDisplayPreferences(
            showMealTimes: false,
            mealNotesEnabled: false,
            showMealNotePreview: true,
          ),
          readError: StateError('read failed'),
        ),
      );

      await controller.load();

      expect(controller.preferences, const MealDiaryDisplayPreferences());
      expect(controller.loadError, isA<StateError>());
      expect(controller.saveError, isNull);
    });

    test('each toggle persists through the same canonical controller',
        () async {
      final repository = _FakeRepository();
      final controller = MealDiaryDisplayPreferencesController(repository);
      await controller.load();

      await controller.setShowMealTimes(false);
      await controller.setShowMealNotePreview(true);
      await controller.setMealNotesEnabled(false);

      expect(
        repository.value,
        const MealDiaryDisplayPreferences(
          showMealTimes: false,
          mealNotesEnabled: false,
          showMealNotePreview: true,
        ),
      );
      expect(controller.preferences, repository.value);
      expect(controller.isSaving, isFalse);
    });

    test('Meal Notes OFF preserves the stored preview preference', () async {
      final repository = _FakeRepository(
        value: const MealDiaryDisplayPreferences(
          showMealNotePreview: true,
        ),
      );
      final controller = MealDiaryDisplayPreferencesController(repository);
      await controller.load();

      await controller.setMealNotesEnabled(false);
      await controller.setShowMealNotePreview(false);

      expect(controller.preferences.mealNotesEnabled, isFalse);
      expect(controller.preferences.showMealNotePreview, isTrue);
      expect(repository.value.showMealNotePreview, isTrue);

      await controller.setMealNotesEnabled(true);
      expect(controller.preferences.showMealNotePreview, isTrue);
    });

    test('publishes immediately and rolls back a failed current write',
        () async {
      final repository = _ControlledRepository();
      final controller = MealDiaryDisplayPreferencesController(repository);
      await controller.load();

      final pending = controller.setShowMealTimes(false);
      await Future<void>.delayed(Duration.zero);

      expect(controller.preferences.showMealTimes, isFalse);
      expect(controller.isSaving, isTrue);

      repository.failNextWrite(StateError('write failed'));
      await pending;

      expect(controller.preferences, const MealDiaryDisplayPreferences());
      expect(controller.saveError, isA<StateError>());
      expect(controller.isSaving, isFalse);
    });

    test('rapid writes stay serialized while the latest choice stays visible',
        () async {
      final repository = _ControlledRepository();
      final controller = MealDiaryDisplayPreferencesController(repository);
      await controller.load();

      final first = controller.setShowMealTimes(false);
      await Future<void>.delayed(Duration.zero);
      final second = controller.setMealNotesEnabled(false);
      await Future<void>.delayed(Duration.zero);

      expect(controller.preferences.showMealTimes, isFalse);
      expect(controller.preferences.mealNotesEnabled, isFalse);
      expect(repository.writeCalls, hasLength(1));

      repository.completeNextWrite();
      await first;
      await Future<void>.delayed(Duration.zero);

      expect(repository.writeCalls, hasLength(2));
      repository.completeNextWrite();
      await second;

      expect(
        repository.value,
        const MealDiaryDisplayPreferences(
          showMealTimes: false,
          mealNotesEnabled: false,
        ),
      );
      expect(controller.isSaving, isFalse);
      expect(controller.saveError, isNull);
    });

    test('a superseded write failure never rolls back a newer choice',
        () async {
      final repository = _ControlledRepository();
      final controller = MealDiaryDisplayPreferencesController(repository);
      await controller.load();

      final first = controller.setShowMealTimes(false);
      await Future<void>.delayed(Duration.zero);
      final second = controller.setMealNotesEnabled(false);
      await Future<void>.delayed(Duration.zero);

      repository.failNextWrite(StateError('old write failed'));
      await first;
      await Future<void>.delayed(Duration.zero);

      expect(controller.preferences.showMealTimes, isFalse);
      expect(controller.preferences.mealNotesEnabled, isFalse);
      expect(controller.saveError, isNull);

      repository.completeNextWrite();
      await second;
      expect(controller.saveError, isNull);
    });
  });
}

class _FakeRepository implements MealDiaryDisplayPreferencesRepository {
  _FakeRepository({
    this.value = const MealDiaryDisplayPreferences(),
    this.readError,
    this.writeError,
  });

  MealDiaryDisplayPreferences value;
  final Object? readError;
  final Object? writeError;

  @override
  Future<MealDiaryDisplayPreferences> read() async {
    if (readError case final error?) throw error;
    return value;
  }

  @override
  Future<void> write(MealDiaryDisplayPreferences preferences) async {
    if (writeError case final error?) throw error;
    value = preferences;
  }

  @override
  Future<void> clear() async => value = const MealDiaryDisplayPreferences();
}

class _ControlledRepository implements MealDiaryDisplayPreferencesRepository {
  MealDiaryDisplayPreferences value = const MealDiaryDisplayPreferences();
  final List<MealDiaryDisplayPreferences> writeCalls = [];
  final List<Completer<void>> _writes = [];

  void completeNextWrite() => _pendingWrite().complete();

  void failNextWrite(Object error) => _pendingWrite().completeError(error);

  Completer<void> _pendingWrite() =>
      _writes.firstWhere((write) => !write.isCompleted);

  @override
  Future<MealDiaryDisplayPreferences> read() async => value;

  @override
  Future<void> write(MealDiaryDisplayPreferences preferences) async {
    writeCalls.add(preferences);
    final write = Completer<void>();
    _writes.add(write);
    await write.future;
    value = preferences;
  }

  @override
  Future<void> clear() async => value = const MealDiaryDisplayPreferences();
}

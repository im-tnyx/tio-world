import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/calendar_preferences.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  group('CalendarPreferencesController', () {
    test('loads a stored Sunday preference', () async {
      final controller = CalendarPreferencesController(
        _FakeCalendarPreferencesRepository(
          const CalendarPreferences(
            firstDayOfWeek: FirstDayOfWeekPreference.sunday,
          ),
        ),
      );

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.sunday);
      expect(controller.resolvedFirstDayOfWeek, DateTime.sunday);
      expect(controller.loadError, isNull);
      expect(controller.saveError, isNull);
    });

    test('select persists Sunday then Monday through the same controller',
        () async {
      final repository = _FakeCalendarPreferencesRepository(
        const CalendarPreferences(),
      );
      final controller = CalendarPreferencesController(repository);
      await controller.load();

      await controller.select(FirstDayOfWeekPreference.sunday);
      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.sunday);
      expect(repository.value.firstDayOfWeek, FirstDayOfWeekPreference.sunday);

      await controller.select(FirstDayOfWeekPreference.monday);
      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.monday);
      expect(repository.value.firstDayOfWeek, FirstDayOfWeekPreference.monday);
      expect(controller.isSaving, isFalse);
    });

    test('does not publish a value when persistence fails', () async {
      final repository = _FakeCalendarPreferencesRepository(
        const CalendarPreferences(),
        writeError: StateError('write failed'),
      );
      final controller = CalendarPreferencesController(repository);
      await controller.load();

      await expectLater(
        controller.select(FirstDayOfWeekPreference.sunday),
        throwsStateError,
      );

      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.monday);
      expect(controller.loadError, isNull);
      expect(controller.saveError, isA<StateError>());
      expect(controller.isSaving, isFalse);
    });

    test('falls back to Monday after a read failure without a save error',
        () async {
      final controller = CalendarPreferencesController(
        _FakeCalendarPreferencesRepository(
          const CalendarPreferences(
            firstDayOfWeek: FirstDayOfWeekPreference.sunday,
          ),
          readError: StateError('read failed'),
        ),
      );

      await controller.load();

      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.monday);
      expect(controller.loadError, isA<StateError>());
      expect(controller.saveError, isNull);
    });

    test('serializes concurrent choices in tap order', () async {
      final repository = _ControlledCalendarPreferencesRepository();
      final controller = CalendarPreferencesController(repository);
      await controller.load();

      final sunday = controller.select(FirstDayOfWeekPreference.sunday);
      final monday = controller.select(FirstDayOfWeekPreference.monday);
      await Future<void>.delayed(Duration.zero);

      expect(repository.writeCalls, [FirstDayOfWeekPreference.sunday]);
      expect(controller.isSaving, isTrue);

      repository.completeNextWrite();
      await sunday;
      await Future<void>.delayed(Duration.zero);
      expect(repository.writeCalls, [
        FirstDayOfWeekPreference.sunday,
        FirstDayOfWeekPreference.monday,
      ]);

      repository.completeNextWrite();
      await monday;

      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.monday);
      expect(controller.isSaving, isFalse);
    });
  });
}

class _FakeCalendarPreferencesRepository
    implements CalendarPreferencesRepository {
  _FakeCalendarPreferencesRepository(
    this.value, {
    this.readError,
    this.writeError,
  });

  CalendarPreferences value;
  final Object? readError;
  final Object? writeError;

  @override
  Future<void> clear() async => value = const CalendarPreferences();

  @override
  Future<CalendarPreferences> read() async {
    if (readError case final error?) throw error;
    return value;
  }

  @override
  Future<void> write(CalendarPreferences preferences) async {
    if (writeError case final error?) throw error;
    value = preferences;
  }
}

class _ControlledCalendarPreferencesRepository
    implements CalendarPreferencesRepository {
  final List<FirstDayOfWeekPreference> writeCalls = [];
  final List<Completer<void>> _writes = [];
  CalendarPreferences value = const CalendarPreferences();

  void completeNextWrite() {
    final index = _writes.indexWhere((write) => !write.isCompleted);
    _writes[index].complete();
  }

  @override
  Future<void> clear() async => value = const CalendarPreferences();

  @override
  Future<CalendarPreferences> read() async => value;

  @override
  Future<void> write(CalendarPreferences preferences) async {
    writeCalls.add(preferences.firstDayOfWeek);
    final write = Completer<void>();
    _writes.add(write);
    await write.future;
    value = preferences;
  }
}

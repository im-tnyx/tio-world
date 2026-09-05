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

    test('publishes the chosen week start before storage answers', () async {
      final repository = _ControlledCalendarPreferencesRepository();
      final controller = CalendarPreferencesController(repository);
      await controller.load();

      var notifications = 0;
      controller.addListener(() => notifications++);

      final pending = controller.select(FirstDayOfWeekPreference.wednesday);
      await Future<void>.delayed(Duration.zero);

      // Immediate apply means the chosen card and Meal Diary both move now.
      // A slow or hung device-local write must not hold the UI on the old
      // week start until it answers.
      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(controller.resolvedFirstDayOfWeek, DateTime.wednesday);
      expect(controller.isSaving, isTrue);
      expect(notifications, greaterThan(0));

      repository.completeNextWrite();
      await pending;

      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(controller.isSaving, isFalse);
      expect(controller.saveError, isNull);
    });

    test('rolls the published value back when persistence fails', () async {
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

    test('a second choice publishes while the first write is still open',
        () async {
      final repository = _ControlledCalendarPreferencesRepository();
      final controller = CalendarPreferencesController(repository);
      await controller.load();

      final published = <FirstDayOfWeekPreference>[];
      controller.addListener(() => published.add(controller.firstDayOfWeek));

      final tuesday = controller.select(FirstDayOfWeekPreference.tuesday);
      await Future<void>.delayed(Duration.zero);
      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.tuesday);

      // Tuesday's write is deliberately left open. Seven visible options make
      // out-running a slow device-local store a realistic interaction, and the
      // second tap must not wait in line behind the first one's storage.
      final wednesday = controller.select(FirstDayOfWeekPreference.wednesday);
      await Future<void>.delayed(Duration.zero);

      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(controller.resolvedFirstDayOfWeek, DateTime.wednesday);
      expect(published, contains(FirstDayOfWeekPreference.wednesday));
      expect(repository.writeCalls, [FirstDayOfWeekPreference.tuesday]);

      repository.completeNextWrite();
      await tuesday;
      await Future<void>.delayed(Duration.zero);
      repository.completeNextWrite();
      await wednesday;

      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(controller.isSaving, isFalse);
      expect(controller.saveError, isNull);
    });

    test('publishing ahead of the queue keeps the writes in tap order',
        () async {
      final repository = _ControlledCalendarPreferencesRepository();
      final controller = CalendarPreferencesController(repository);
      await controller.load();

      final tuesday = controller.select(FirstDayOfWeekPreference.tuesday);
      final wednesday = controller.select(FirstDayOfWeekPreference.wednesday);
      await Future<void>.delayed(Duration.zero);

      // The screen has already moved on, but only one write is in flight: an
      // older write finishing last would leave the device holding a value the
      // user replaced.
      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(repository.writeCalls, [FirstDayOfWeekPreference.tuesday]);

      repository.completeNextWrite();
      await tuesday;
      await Future<void>.delayed(Duration.zero);

      expect(repository.writeCalls, [
        FirstDayOfWeekPreference.tuesday,
        FirstDayOfWeekPreference.wednesday,
      ]);

      repository.completeNextWrite();
      await wednesday;

      expect(repository.value.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(controller.isSaving, isFalse);
    });

    test('a superseded write failure leaves the newer choice alone', () async {
      final repository = _ControlledCalendarPreferencesRepository();
      final controller = CalendarPreferencesController(repository);
      await controller.load();

      final tuesday = controller.select(FirstDayOfWeekPreference.tuesday);
      await Future<void>.delayed(Duration.zero);
      final wednesday = controller.select(FirstDayOfWeekPreference.wednesday);
      await Future<void>.delayed(Duration.zero);

      repository.failNextWrite(StateError('tuesday write failed'));
      await tuesday;
      await Future<void>.delayed(Duration.zero);

      // Tuesday is no longer what the user wants. Rolling back or reporting a
      // failure for it would undo an intent expressed after that write left.
      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(controller.saveError, isNull);

      repository.completeNextWrite();
      await wednesday;

      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(repository.value.firstDayOfWeek, FirstDayOfWeekPreference.wednesday);
      expect(controller.saveError, isNull);
      expect(controller.isSaving, isFalse);
    });

    test('rollback returns to what storage holds, not to what was on screen',
        () async {
      final repository = _ControlledCalendarPreferencesRepository();
      final controller = CalendarPreferencesController(repository);
      await controller.load();

      final tuesday = controller.select(FirstDayOfWeekPreference.tuesday);
      await Future<void>.delayed(Duration.zero);
      final wednesday = controller.select(FirstDayOfWeekPreference.wednesday);
      await Future<void>.delayed(Duration.zero);

      // Neither write lands, so the device still holds Monday. Falling back to
      // Tuesday because it happened to be on screen first would show a value
      // that was never saved.
      repository.failNextWrite(StateError('tuesday write failed'));
      await tuesday;
      await Future<void>.delayed(Duration.zero);

      repository.failNextWrite(StateError('wednesday write failed'));
      await expectLater(wednesday, throwsStateError);

      expect(controller.firstDayOfWeek, FirstDayOfWeekPreference.monday);
      expect(controller.saveError, isA<StateError>());
      expect(controller.isSaving, isFalse);
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
    _pendingWrite().complete();
  }

  void failNextWrite(Object error) {
    _pendingWrite().completeError(error);
  }

  Completer<void> _pendingWrite() =>
      _writes.firstWhere((write) => !write.isCompleted);

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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('AppModeController', () {
    test('loads a stored mode', () async {
      final preference = _FakeAppModePreference(initialMode: AppMode.workout);
      final controller = AppModeController(preference);

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.selectedMode, AppMode.workout);
      expect(
        controller.activeDestinations,
        AppMode.workout.guidedDestinations,
      );
      expect(controller.lastError, isNull);
    });

    test('keeps missing mode as null for onboarding', () async {
      final controller = AppModeController(_FakeAppModePreference());

      await controller.load();

      expect(controller.selectedMode, isNull);
      expect(controller.activeDestinations, isNull);
    });

    test('persists a confirmed selection before publishing it', () async {
      final preference = _FakeAppModePreference();
      final controller = AppModeController(preference);
      await controller.load();

      await controller.select(AppMode.hybrid);

      expect(preference.storedMode, AppMode.hybrid);
      expect(controller.selectedMode, AppMode.hybrid);
      expect(
        controller.activeDestinations,
        AppMode.hybrid.guidedDestinations,
      );
      expect(controller.isSaving, isFalse);
    });

    test('does not publish a selection when persistence fails', () async {
      final preference =
          _FakeAppModePreference(writeError: StateError('write failed'));
      final controller = AppModeController(preference);
      await controller.load();

      await expectLater(controller.select(AppMode.nutrition), throwsStateError);

      expect(controller.selectedMode, isNull);
      expect(controller.activeDestinations, isNull);
      expect(controller.lastError, isA<StateError>());
      expect(controller.isSaving, isFalse);
    });

    test('serializes concurrent selections and persists the latest mode',
        () async {
      final preference = _ControlledAppModePreference();
      final controller = AppModeController(preference);
      await controller.load();

      final workoutWrite = controller.select(AppMode.workout);
      final nutritionWrite = controller.select(AppMode.nutrition);
      await Future<void>.delayed(Duration.zero);

      expect(preference.writeCalls, [AppMode.workout]);
      expect(controller.isSaving, isTrue);

      preference.completeNextWrite();
      await workoutWrite;
      await Future<void>.delayed(Duration.zero);

      expect(preference.writeCalls, [AppMode.workout, AppMode.nutrition]);
      expect(controller.isSaving, isTrue);

      preference.completeNextWrite();
      await nutritionWrite;

      expect(controller.selectedMode, AppMode.nutrition);
      expect(preference.storedMode, AppMode.nutrition);
      expect(
        controller.activeDestinations,
        AppMode.nutrition.guidedDestinations,
      );
      expect(controller.isSaving, isFalse);
    });

    test('continues queued selections after an earlier write fails', () async {
      final preference = _FailFirstAppModePreference();
      final controller = AppModeController(preference);
      await controller.load();

      final failedWrite = controller.select(AppMode.workout);
      final failedExpectation = expectLater(failedWrite, throwsStateError);
      final successfulWrite = controller.select(AppMode.nutrition);

      await failedExpectation;
      await successfulWrite;

      expect(controller.selectedMode, AppMode.nutrition);
      expect(preference.storedMode, AppMode.nutrition);
      expect(
        controller.activeDestinations,
        AppMode.nutrition.guidedDestinations,
      );
      expect(controller.lastError, isNull);
      expect(controller.isSaving, isFalse);
    });

    test('authenticated selection commits canonical preference before publishing',
        () async {
      final preference = _FakeAppModePreference(initialMode: AppMode.workout);
      final controller = AppModeController(preference);
      await controller.load();
      final repository = _RecordingAppPreferencesRepository(
        onUpsert: (update) {
          expect(controller.selectedMode, AppMode.workout);
          expect(controller.activeDestinations, AppMode.workout.guidedDestinations);
          expect(preference.storedMode, AppMode.workout);
          expect(update.appMode, AppMode.nutrition);
          expect(update.activeTabs, AppMode.nutrition.guidedDestinations);
        },
      );
      controller.setAuthenticatedWriteRepository(repository);

      await controller.select(AppMode.nutrition);

      expect(repository.updates, hasLength(1));
      expect(repository.updates.single.appMode, AppMode.nutrition);
      expect(
        repository.updates.single.activeTabs,
        AppMode.nutrition.guidedDestinations,
      );
      expect(preference.storedMode, AppMode.nutrition);
      expect(controller.selectedMode, AppMode.nutrition);
      expect(
        controller.activeDestinations,
        AppMode.nutrition.guidedDestinations,
      );
      expect(controller.lastError, isNull);
    });

    test('canonical write failure preserves current runtime and local mode',
        () async {
      final preference = _FakeAppModePreference(initialMode: AppMode.workout);
      final controller = AppModeController(preference);
      await controller.load();
      final repository = _RecordingAppPreferencesRepository(
        upsertError: StateError('remote write failed'),
      );
      controller.setAuthenticatedWriteRepository(repository);

      await expectLater(controller.select(AppMode.hybrid), throwsStateError);

      expect(repository.updates, hasLength(1));
      expect(preference.storedMode, AppMode.workout);
      expect(controller.selectedMode, AppMode.workout);
      expect(
        controller.activeDestinations,
        AppMode.workout.guidedDestinations,
      );
      expect(controller.lastError, isA<StateError>());
      expect(controller.isSaving, isFalse);
    });

    test('canonical success remains authoritative if local cache refresh fails',
        () async {
      final preference = _FakeAppModePreference(
        initialMode: AppMode.workout,
        writeError: StateError('cache write failed'),
      );
      final controller = AppModeController(preference);
      await controller.load();
      final repository = _RecordingAppPreferencesRepository();
      controller.setAuthenticatedWriteRepository(repository);

      await controller.select(AppMode.hybrid);

      expect(repository.updates, hasLength(1));
      expect(repository.updates.single.appMode, AppMode.hybrid);
      expect(preference.storedMode, AppMode.workout);
      expect(controller.selectedMode, AppMode.hybrid);
      expect(
        controller.activeDestinations,
        AppMode.hybrid.guidedDestinations,
      );
      expect(controller.lastError, isA<StateError>());
      expect(controller.isSaving, isFalse);
    });

    test('disabling authenticated writes restores local staging behavior',
        () async {
      final preference = _FakeAppModePreference(initialMode: AppMode.workout);
      final controller = AppModeController(preference);
      await controller.load();
      final repository = _RecordingAppPreferencesRepository();
      controller.setAuthenticatedWriteRepository(repository);
      controller.setAuthenticatedWriteRepository(null);

      await controller.select(AppMode.nutrition);

      expect(repository.updates, isEmpty);
      expect(preference.storedMode, AppMode.nutrition);
      expect(controller.selectedMode, AppMode.nutrition);
    });

    test('canonical restore overrides stale local mode and preserves tab order',
        () async {
      final preference = _FakeAppModePreference(initialMode: AppMode.workout);
      final controller = AppModeController(preference);
      await controller.load();

      await controller.restoreCanonical(
        AppPreferencesState.present(
          appMode: AppMode.nutrition,
          activeTabs: const [
            AppDestination.progress,
            AppDestination.home,
            AppDestination.nutrition,
          ],
        ),
      );

      expect(preference.storedMode, AppMode.nutrition);
      expect(controller.selectedMode, AppMode.nutrition);
      expect(
        controller.activeDestinations,
        const [
          AppDestination.progress,
          AppDestination.home,
          AppDestination.nutrition,
        ],
      );
      expect(controller.lastError, isNull);
    });

    test('canonical app-mode-only row derives guided destinations', () async {
      final controller = AppModeController(_FakeAppModePreference());
      await controller.load();

      await controller.restoreCanonical(
        AppPreferencesState.present(
          appMode: AppMode.workout,
          activeTabs: null,
        ),
      );

      expect(controller.selectedMode, AppMode.workout);
      expect(
        controller.activeDestinations,
        AppMode.workout.guidedDestinations,
      );
    });

    test('missing canonical state clears stale device semantic mode', () async {
      final preference = _FakeAppModePreference(initialMode: AppMode.hybrid);
      final controller = AppModeController(preference);
      await controller.load();

      await controller.restoreMissingCanonical();

      expect(preference.storedMode, isNull);
      expect(controller.selectedMode, isNull);
      expect(controller.activeDestinations, isNull);
    });

    test('canonical restore never invents a mode when remote mode is null',
        () async {
      final preference = _FakeAppModePreference(initialMode: AppMode.workout);
      final controller = AppModeController(preference);
      await controller.load();

      await expectLater(
        controller.restoreCanonical(
          AppPreferencesState.present(
            appMode: null,
            activeTabs: const [AppDestination.home],
          ),
        ),
        throwsStateError,
      );

      expect(controller.selectedMode, AppMode.workout);
      expect(preference.storedMode, AppMode.workout);
    });

    test('valid remote state remains authoritative if local cache write fails',
        () async {
      final preference = _FakeAppModePreference(
        initialMode: AppMode.workout,
        writeError: StateError('cache write failed'),
      );
      final controller = AppModeController(preference);
      await controller.load();

      await controller.restoreCanonical(
        AppPreferencesState.present(
          appMode: AppMode.nutrition,
          activeTabs: const [
            AppDestination.home,
            AppDestination.progress,
            AppDestination.nutrition,
          ],
        ),
      );

      expect(preference.storedMode, AppMode.workout);
      expect(controller.selectedMode, AppMode.nutrition);
      expect(
        controller.activeDestinations,
        const [
          AppDestination.home,
          AppDestination.progress,
          AppDestination.nutrition,
        ],
      );
      expect(controller.lastError, isA<StateError>());
    });

    testWidgets('renders the app before stored mode loading completes',
        (tester) async {
      final preference = _ControlledAppModePreference(blockRead: true);
      final controller = AppModeController(preference);

      await tester.pumpWidget(
        AppModeBootstrap(
          controller: controller,
          child: const MaterialApp(home: Text('Splash content')),
        ),
      );

      expect(find.text('Splash content'), findsOneWidget);
      expect(controller.isLoaded, isFalse);

      preference.completeRead(AppMode.hybrid);
      await tester.pump();

      expect(controller.isLoaded, isTrue);
      expect(controller.selectedMode, AppMode.hybrid);
      expect(
        controller.activeDestinations,
        AppMode.hybrid.guidedDestinations,
      );
    });
  });

  group('AppMode contract', () {
    test('parses only supported stored values', () {
      expect(AppMode.fromStorageValue('workout'), AppMode.workout);
      expect(AppMode.fromStorageValue('nutrition'), AppMode.nutrition);
      expect(AppMode.fromStorageValue('hybrid'), AppMode.hybrid);
      expect(AppMode.fromStorageValue('custom'), isNull);
      expect(AppMode.fromStorageValue(null), isNull);
    });

    test('exposes the approved guided destinations', () {
      expect(
        AppMode.workout.guidedDestinations,
        const [
          AppDestination.home,
          AppDestination.workout,
          AppDestination.progress
        ],
      );
      expect(
        AppMode.nutrition.guidedDestinations,
        const [
          AppDestination.home,
          AppDestination.nutrition,
          AppDestination.progress
        ],
      );
      expect(
        AppMode.hybrid.guidedDestinations,
        const [
          AppDestination.home,
          AppDestination.workout,
          AppDestination.nutrition,
          AppDestination.progress,
        ],
      );
    });
  });
}

class _RecordingAppPreferencesRepository implements AppPreferencesRepository {
  _RecordingAppPreferencesRepository({
    this.onUpsert,
    this.upsertError,
  });

  final void Function(AppPreferencesUpdate update)? onUpsert;
  final Object? upsertError;
  final List<AppPreferencesUpdate> updates = [];

  @override
  Future<AppPreferencesState> read() async =>
      const AppPreferencesState.missing();

  @override
  Future<void> upsert(AppPreferencesUpdate preferences) async {
    updates.add(preferences);
    onUpsert?.call(preferences);
    if (upsertError case final error?) throw error;
  }
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference({AppMode? initialMode, this.writeError})
      : storedMode = initialMode;

  AppMode? storedMode;
  final Object? writeError;

  @override
  Future<void> clear() async {
    storedMode = null;
  }

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
    if (writeError case final error?) throw error;
    storedMode = mode;
  }
}

class _ControlledAppModePreference implements AppModePreference {
  _ControlledAppModePreference({this.blockRead = false});

  final bool blockRead;
  final List<AppMode> writeCalls = [];
  final List<Completer<void>> _writes = [];
  final Completer<AppMode?> _read = Completer<AppMode?>();
  AppMode? storedMode;

  @override
  Future<void> clear() async {
    storedMode = null;
  }

  void completeNextWrite() {
    final index = _writes.indexWhere((write) => !write.isCompleted);
    _writes[index].complete();
  }

  void completeRead(AppMode? mode) => _read.complete(mode);

  @override
  Future<AppMode?> read() =>
      blockRead ? _read.future : Future<AppMode?>.value(storedMode);

  @override
  Future<void> write(AppMode mode) async {
    writeCalls.add(mode);
    final write = Completer<void>();
    _writes.add(write);
    await write.future;
    storedMode = mode;
  }
}

class _FailFirstAppModePreference implements AppModePreference {
  int _writeCount = 0;
  AppMode? storedMode;

  @override
  Future<void> clear() async => storedMode = null;

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async {
    _writeCount++;
    if (_writeCount == 1) throw StateError('first write failed');
    storedMode = mode;
  }
}

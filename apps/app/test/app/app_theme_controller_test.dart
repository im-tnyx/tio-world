import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_core/core.dart';

void main() {
  group('AppThemeController', () {
    test('loads a stored theme mode', () async {
      final controller = AppThemeController(
        _FakeAppThemePreference(initialMode: TioThemeMode.dark),
      );

      await controller.load();

      expect(controller.isLoaded, isTrue);
      expect(controller.selectedMode, TioThemeMode.dark);
      expect(controller.themeConfig.mode, TioThemeMode.dark);
      expect(controller.lastError, isNull);
    });

    test('uses system mode when no value is persisted', () async {
      final controller = AppThemeController(_FakeAppThemePreference());

      await controller.load();

      expect(controller.selectedMode, TioThemeMode.system);
    });

    test('persists a confirmed theme selection before publishing it', () async {
      final preference = _FakeAppThemePreference();
      final controller = AppThemeController(preference);
      await controller.load();

      await controller.select(TioThemeMode.oled);

      expect(preference.storedMode, TioThemeMode.oled);
      expect(controller.selectedMode, TioThemeMode.oled);
      expect(controller.isSaving, isFalse);
    });

    test('does not publish a theme when persistence fails', () async {
      final preference =
          _FakeAppThemePreference(writeError: StateError('write failed'));
      final controller = AppThemeController(preference);
      await controller.load();

      await expectLater(
          controller.select(TioThemeMode.light), throwsStateError);

      expect(controller.selectedMode, TioThemeMode.system);
      expect(controller.lastError, isA<StateError>());
      expect(controller.isSaving, isFalse);
    });

    test('serializes concurrent theme selections and persists the latest mode',
        () async {
      final preference = _ControlledAppThemePreference();
      final controller = AppThemeController(preference);
      await controller.load();

      final darkWrite = controller.select(TioThemeMode.dark);
      final oledWrite = controller.select(TioThemeMode.oled);
      await Future<void>.delayed(Duration.zero);

      expect(preference.writeCalls, [TioThemeMode.dark]);
      expect(controller.isSaving, isTrue);

      preference.completeNextWrite();
      await darkWrite;
      await Future<void>.delayed(Duration.zero);

      expect(preference.writeCalls, [TioThemeMode.dark, TioThemeMode.oled]);
      expect(controller.isSaving, isTrue);

      preference.completeNextWrite();
      await oledWrite;

      expect(controller.selectedMode, TioThemeMode.oled);
      expect(preference.storedMode, TioThemeMode.oled);
      expect(controller.isSaving, isFalse);
    });
  });
}

class _FakeAppThemePreference implements AppThemePreference {
  _FakeAppThemePreference({TioThemeMode? initialMode, this.writeError})
      : storedMode = initialMode;

  TioThemeMode? storedMode;
  final Object? writeError;

  @override
  Future<void> clear() async {
    storedMode = null;
  }

  @override
  Future<TioThemeMode?> read() async => storedMode;

  @override
  Future<void> write(TioThemeMode mode) async {
    if (writeError case final error?) throw error;
    storedMode = mode;
  }
}

class _ControlledAppThemePreference implements AppThemePreference {
  final List<TioThemeMode> writeCalls = [];
  final List<Completer<void>> _writes = [];
  TioThemeMode? storedMode;

  @override
  Future<void> clear() async {
    storedMode = null;
  }

  void completeNextWrite() {
    final index = _writes.indexWhere((write) => !write.isCompleted);
    _writes[index].complete();
  }

  @override
  Future<TioThemeMode?> read() async => storedMode;

  @override
  Future<void> write(TioThemeMode mode) async {
    writeCalls.add(mode);
    final write = Completer<void>();
    _writes.add(write);
    await write.future;
    storedMode = mode;
  }
}

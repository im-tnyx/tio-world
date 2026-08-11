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
      expect(controller.lastError, isNull);
    });

    test('keeps missing mode as null for onboarding', () async {
      final controller = AppModeController(_FakeAppModePreference());

      await controller.load();

      expect(controller.selectedMode, isNull);
    });

    test('persists a confirmed selection before publishing it', () async {
      final preference = _FakeAppModePreference();
      final controller = AppModeController(preference);
      await controller.load();

      await controller.select(AppMode.hybrid);

      expect(preference.storedMode, AppMode.hybrid);
      expect(controller.selectedMode, AppMode.hybrid);
      expect(controller.isSaving, isFalse);
    });

    test('does not publish a selection when persistence fails', () async {
      final preference =
          _FakeAppModePreference(writeError: StateError('write failed'));
      final controller = AppModeController(preference);
      await controller.load();

      await expectLater(controller.select(AppMode.nutrition), throwsStateError);

      expect(controller.selectedMode, isNull);
      expect(controller.lastError, isA<StateError>());
      expect(controller.isSaving, isFalse);
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

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('Ready canonical requirement never falls back to local-only save',
      () async {
    final preference = _FakeAppModePreference(AppMode.workout);
    final controller = AppModeController(preference);
    await controller.load();
    controller.setAuthenticatedWriteRepository(
      null,
      requireCanonical: true,
    );

    await expectLater(controller.select(AppMode.nutrition), throwsStateError);

    expect(preference.storedMode, AppMode.workout);
    expect(controller.selectedMode, AppMode.workout);
    expect(controller.activeDestinations, AppMode.workout.guidedDestinations);
    expect(controller.lastError, isA<StateError>());
  });
}

class _FakeAppModePreference implements AppModePreference {
  _FakeAppModePreference(this.storedMode);

  AppMode? storedMode;

  @override
  Future<void> clear() async => storedMode = null;

  @override
  Future<AppMode?> read() async => storedMode;

  @override
  Future<void> write(AppMode mode) async => storedMode = mode;
}

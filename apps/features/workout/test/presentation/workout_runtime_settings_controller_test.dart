import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

final class _Repository implements WorkoutRuntimeSettingsRepository {
  int? seconds;

  @override
  Future<void> clearDefaultRestSeconds() async => seconds = null;

  @override
  Future<int?> readDefaultRestSeconds() async => seconds;

  @override
  Future<void> writeDefaultRestSeconds(int seconds) async =>
      this.seconds = seconds;
}

void main() {
  test('unset resolves to OFF but remains distinct from explicit OFF', () async {
    final repository = _Repository();
    final controller = WorkoutRuntimeSettingsController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.isReady, isTrue);
    expect(controller.savedDefaultRestSeconds, isNull);
    expect(controller.effectiveDefaultRestSeconds, 0);
    expect(controller.defaultRestPreset.isOff, isTrue);

    await controller.setDefaultRestSeconds(null);
    expect(repository.seconds, 0);
    expect(controller.savedDefaultRestSeconds, 0);
    expect(controller.defaultRestPreset.isOff, isTrue);

    await controller.setDefaultRestSeconds(60);
    expect(controller.savedDefaultRestSeconds, 60);
    expect(controller.defaultRestLabel, '1min');
  });

  test('rejects values outside the existing wheel contract', () async {
    final controller = WorkoutRuntimeSettingsController(repository: _Repository());
    addTearDown(controller.dispose);
    await controller.load();

    await expectLater(
      controller.setDefaultRestSeconds(61),
      throwsArgumentError,
    );
    await expectLater(
      controller.setDefaultRestSeconds(605),
      throwsArgumentError,
    );
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

final class _Repository implements WorkoutRuntimeSettingsRepository {
  bool vibrationEnabled = false;
  bool failNextVibrationRead = false;

  @override
  Future<bool> readRestTimerVibrationEnabled() async {
    if (failNextVibrationRead) {
      failNextVibrationRead = false;
      throw StateError('Simulated vibration storage read failure');
    }
    return vibrationEnabled;
  }

  @override
  Future<void> writeRestTimerVibrationEnabled(bool enabled) async {
    vibrationEnabled = enabled;
  }

  int? seconds;
  int readCount = 0;
  bool failNextRead = false;

  @override
  Future<void> clearDefaultRestSeconds() async => seconds = null;

  @override
  Future<int?> readDefaultRestSeconds() async {
    readCount++;
    if (failNextRead) {
      failNextRead = false;
      throw StateError('Simulated local storage read failure');
    }
    return seconds;
  }

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

  test('failed local read can retry and restore the saved default', () async {
    final repository = _Repository()
      ..seconds = 60
      ..failNextRead = true;
    final controller = WorkoutRuntimeSettingsController(repository: repository);
    addTearDown(controller.dispose);

    await controller.load();
    expect(controller.isLoaded, isFalse);
    expect(controller.isLoading, isFalse);
    expect(controller.error, isA<StateError>());
    expect(repository.readCount, 1);

    await controller.load();
    expect(repository.readCount, 2);
    expect(controller.isReady, isTrue);
    expect(controller.error, isNull);
    expect(controller.savedDefaultRestSeconds, 60);
    expect(controller.defaultRestLabel, '1min');
  });

  test('vibration OFF by default and ON/OFF changes do not affect rest',
      () async {
    final repository = _Repository()..seconds = 90;
    final controller = WorkoutRuntimeSettingsController(repository: repository);
    addTearDown(controller.dispose);

    await controller.loadRestTimerVibration();
    expect(controller.isVibrationReady, isTrue);
    expect(controller.restTimerVibrationEnabled, isFalse);
    await controller.setRestTimerVibrationEnabled(true);
    expect(controller.restTimerVibrationEnabled, isTrue);
    expect(repository.vibrationEnabled, isTrue);
    await controller.setRestTimerVibrationEnabled(false);
    expect(controller.restTimerVibrationEnabled, isFalse);
    await controller.load();
    expect(controller.savedDefaultRestSeconds, 90);
  });

  test('vibration read failure is retryable and does not block Default Rest',
      () async {
    final repository = _Repository()
      ..seconds = 60
      ..failNextVibrationRead = true;
    final controller = WorkoutRuntimeSettingsController(repository: repository);
    addTearDown(controller.dispose);

    await controller.loadRestTimerVibration();
    expect(controller.isVibrationReady, isFalse);
    expect(controller.restTimerVibrationEnabled, isFalse);
    expect(controller.vibrationError, isA<StateError>());
    await controller.load();
    expect(controller.isReady, isTrue);
    expect(controller.effectiveDefaultRestSeconds, 60);

    await controller.loadRestTimerVibration();
    expect(controller.isVibrationReady, isTrue);
    expect(controller.vibrationError, isNull);
    expect(controller.restTimerVibrationEnabled, isFalse);
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

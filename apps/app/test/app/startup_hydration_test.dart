import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/startup_hydration.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('startup hydrates mode and theme together, then status after mode',
      () async {
    final events = <String>[];
    final modePreference = _ControlledAppModePreference(events);
    final themePreference = _ControlledAppThemePreference(events);
    final statusRepository = _RecordingStatusRepository(events);
    final appModeController = AppModeController(modePreference);
    final appThemeController = AppThemeController(themePreference);
    final onboardingStatusController = OnboardingStatusController(
      repository: statusRepository,
      appModeController: appModeController,
    );

    final hydration = hydrateStartupControllers(
      appModeController: appModeController,
      onboardingStatusController: onboardingStatusController,
      appThemeController: appThemeController,
    );
    await Future<void>.delayed(Duration.zero);

    expect(events, ['mode.read', 'theme.read']);
    expect(onboardingStatusController.isLoaded, isFalse);

    modePreference.completeRead(AppMode.workout);
    await Future<void>.delayed(Duration.zero);

    expect(events, ['mode.read', 'theme.read', 'status.read']);
    expect(appModeController.selectedMode, AppMode.workout);
    expect(appThemeController.isLoaded, isFalse);

    themePreference.completeRead(TioThemeMode.dark);
    await hydration;

    expect(appThemeController.selectedMode, TioThemeMode.dark);
    expect(onboardingStatusController.isLoaded, isTrue);
    expect(statusRepository.readCalls, 1);

    await hydrateStartupControllers(
      appModeController: appModeController,
      onboardingStatusController: onboardingStatusController,
      appThemeController: appThemeController,
    );

    expect(modePreference.readCalls, 1);
    expect(themePreference.readCalls, 1);
    expect(statusRepository.readCalls, 1);
  });
}

class _ControlledAppModePreference implements AppModePreference {
  _ControlledAppModePreference(this.events);

  final List<String> events;
  final Completer<AppMode?> _read = Completer<AppMode?>();
  int readCalls = 0;

  void completeRead(AppMode? mode) => _read.complete(mode);

  @override
  Future<AppMode?> read() {
    readCalls += 1;
    events.add('mode.read');
    return _read.future;
  }

  @override
  Future<void> write(AppMode mode) async {}

  @override
  Future<void> clear() async {}
}

class _ControlledAppThemePreference implements AppThemePreference {
  _ControlledAppThemePreference(this.events);

  final List<String> events;
  final Completer<TioThemeMode?> _read = Completer<TioThemeMode?>();
  int readCalls = 0;

  void completeRead(TioThemeMode? mode) => _read.complete(mode);

  @override
  Future<TioThemeMode?> read() {
    readCalls += 1;
    events.add('theme.read');
    return _read.future;
  }

  @override
  Future<void> write(TioThemeMode mode) async {}

  @override
  Future<void> clear() async {}
}

class _RecordingStatusRepository implements OnboardingStatusRepository {
  _RecordingStatusRepository(this.events);

  final List<String> events;
  int readCalls = 0;

  @override
  Future<OnboardingStatusSnapshot> read() async {
    readCalls += 1;
    events.add('status.read');
    return const OnboardingStatusSnapshot(
      status: null,
      hasStoredContractVersion: true,
    );
  }

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<void> write(OnboardingStatus status) async {}

  @override
  Future<void> clear() async {}
}

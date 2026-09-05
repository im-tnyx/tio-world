import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/calendar_preferences.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/startup_hydration.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test(
      'startup hydrates mode, theme and calendar together, then status after '
      'mode', () async {
    final events = <String>[];
    final modePreference = _ControlledAppModePreference(events);
    final themePreference = _ControlledAppThemePreference(events);
    final calendarRepository = _ControlledCalendarPreferencesRepository(events);
    final statusRepository = _RecordingStatusRepository(events);
    final appModeController = AppModeController(modePreference);
    final appThemeController = AppThemeController(themePreference);
    final calendarPreferencesController =
        CalendarPreferencesController(calendarRepository);
    final onboardingStatusController = OnboardingStatusController(
      repository: statusRepository,
      appModeController: appModeController,
    );

    final hydration = hydrateStartupControllers(
      appModeController: appModeController,
      onboardingStatusController: onboardingStatusController,
      appThemeController: appThemeController,
      calendarPreferencesController: calendarPreferencesController,
    );
    await Future<void>.delayed(Duration.zero);

    expect(events, ['mode.read', 'theme.read', 'calendar.read']);
    expect(onboardingStatusController.isLoaded, isFalse);

    modePreference.completeRead(AppMode.workout);
    await Future<void>.delayed(Duration.zero);

    expect(events, ['mode.read', 'theme.read', 'calendar.read', 'status.read']);
    expect(appModeController.selectedMode, AppMode.workout);
    expect(appThemeController.isLoaded, isFalse);
    expect(calendarPreferencesController.isLoaded, isFalse);

    themePreference.completeRead(TioThemeMode.dark);
    calendarRepository.completeRead(
      const CalendarPreferences(firstDayOfWeek: FirstDayOfWeekPreference.sunday),
    );
    await hydration;

    expect(appThemeController.selectedMode, TioThemeMode.dark);
    // The saved week start is in place before the first frame, so no calendar
    // is drawn Monday-first and then reshuffled under a Sunday reader.
    expect(
      calendarPreferencesController.resolvedFirstDayOfWeek,
      DateTime.sunday,
    );
    expect(onboardingStatusController.isLoaded, isTrue);
    expect(statusRepository.readCalls, 1);

    await hydrateStartupControllers(
      appModeController: appModeController,
      onboardingStatusController: onboardingStatusController,
      appThemeController: appThemeController,
      calendarPreferencesController: calendarPreferencesController,
    );

    expect(modePreference.readCalls, 1);
    expect(themePreference.readCalls, 1);
    expect(calendarRepository.readCalls, 1);
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

class _ControlledCalendarPreferencesRepository
    implements CalendarPreferencesRepository {
  _ControlledCalendarPreferencesRepository(this.events);

  final List<String> events;
  final Completer<CalendarPreferences> _read = Completer<CalendarPreferences>();
  int readCalls = 0;

  void completeRead(CalendarPreferences preferences) =>
      _read.complete(preferences);

  @override
  Future<CalendarPreferences> read() {
    readCalls += 1;
    events.add('calendar.read');
    return _read.future;
  }

  @override
  Future<void> write(CalendarPreferences preferences) async {}

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

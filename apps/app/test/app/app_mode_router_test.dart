import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tio_app/app/app.dart';
import 'package:tio_app/app/app_mode/app_mode.dart';
import 'package:tio_app/app/calendar_preferences.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_app/app/app_theme.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_app/app/router.dart';
import 'package:tio_app/app/session/session.dart';
import 'package:tio_app/app/settings_persistence_providers.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_home/home.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_feature_onboarding/onboarding.dart'
    hide
        ProfileGender,
        ProfileGoal,
        ProfileActivityLevel,
        ProfileHealthCondition;
import 'package:tio_feature_profile/profile.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

void main() {
  for (final testCase in const [
    (
      name: 'light',
      platformBrightness: Brightness.light,
      config: TioThemeConfig(),
      expectedIconBrightness: Brightness.dark,
    ),
    (
      name: 'dark',
      platformBrightness: Brightness.dark,
      config: TioThemeConfig(),
      expectedIconBrightness: Brightness.light,
    ),
    (
      name: 'OLED',
      platformBrightness: Brightness.light,
      config: TioThemeConfig(mode: TioThemeMode.oled),
      expectedIconBrightness: Brightness.light,
    ),
  ]) {
    testWidgets('system bar icons follow the resolved ${testCase.name} theme',
        (tester) async {
      final overlay = await _pumpSystemUiOverlay(
        tester,
        platformBrightness: testCase.platformBrightness,
        config: testCase.config,
      );

      expect(
        overlay.statusBarIconBrightness,
        testCase.expectedIconBrightness,
      );
      expect(
        overlay.systemNavigationBarIconBrightness,
        testCase.expectedIconBrightness,
      );
    });
  }

  test('bottom navigation is limited to main tab root routes', () {
    for (final branch in shellBranchRegistry) {
      expect(
        shellChromePolicyForPath(branch.route.path),
        ChromePolicy.mainChrome,
      );
    }

    expect(
      shellChromePolicyForPath('/workout/session'),
      ChromePolicy.noBottomBar,
    );
    expect(
      shellChromePolicyForPath('/nutrition/meal-log'),
      ChromePolicy.noBottomBar,
    );
    expect(
      shellChromePolicyForPath(AppRoutes.profile.path),
      ChromePolicy.fullScreen,
    );
  });

  testWidgets('mode change redirects an active hidden branch to Home',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
    );
    final onboardingStatusController = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: controller,
    );
    await onboardingStatusController.load();
    final themeController = await _createThemeController();
    final calendarController = CalendarPreferencesController(
      _SettingsCalendarPreferencesRepository(),
    );
    await calendarController.load();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        calendarPreferencesControllerProvider
            .overrideWith((ref) => calendarController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(userId: 'test-user'),
            onboardingStatusController: onboardingStatusController,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    router.go(FeatureRoutes.nutrition.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        FeatureRoutes.nutrition.path);
    // The tab keeps the domain name; the screen inside it is the Diary.
    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Nutrition'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Diary'),
      ),
      findsOneWidget,
    );
    // Centre says where in the calendar the reader currently is.
    final visibleMonth = find.byKey(const ValueKey('meal-diary-visible-month'));
    expect(visibleMonth, findsOneWidget);
    final diaryDates = container.read(mealDiaryDateControllerProvider);
    expect(
      tester.widget<Text>(visibleMonth).data,
      tioCompactMonthYearLabel(
        diaryDates.visibleMonth,
        localeName: 'en_US',
      ),
    );
    expect(diaryDates.visibleMonth,
        DateTime(diaryDates.localToday.year, diaryDates.localToday.month));
    final today = diaryDates.localToday;
    final historicalDate = DateTime(today.year, today.month, today.day - 1);
    final todayAction =
        find.byKey(const ValueKey('meal-diary-today-action'));
    expect(todayAction, findsNothing);

    await tester.fling(
      find.byKey(const ValueKey('tio-date-calendar-week-pager')),
      const Offset(400, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(diaryDates.isOnToday, isTrue);
    expect(diaryDates.isTodayVisible, isFalse);
    expect(todayAction, findsOneWidget);

    await tester.tap(todayAction);
    await tester.pumpAndSettle();

    expect(diaryDates.isOnToday, isTrue);
    expect(diaryDates.isTodayVisible, isTrue);
    expect(todayAction, findsNothing);

    diaryDates.select(historicalDate);
    await tester.pumpAndSettle();

    expect(todayAction, findsOneWidget);
    expect(
      find.descendant(
        of: todayAction,
        matching: find.byKey(const ValueKey('meal-diary-today-glyph')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: todayAction, matching: find.byType(SvgPicture)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: todayAction,
        matching: find.text(today.day.toString()),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: todayAction,
        matching: find.text(historicalDate.day.toString()),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: todayAction,
        matching: find.byKey(const ValueKey('meal-diary-today-day-label')),
      ),
      findsOneWidget,
    );
    await tester.tap(todayAction);
    await tester.pumpAndSettle();
    expect(diaryDates.isOnToday, isTrue);
    expect(todayAction, findsNothing);

    await controller.select(AppMode.workout);
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        FeatureRoutes.home.path);
    expect(find.byType(HomePage), findsOneWidget);
  });

  testWidgets(
      'first-run review stays in onboarding while durable persistence blocks completion',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.inProgress,
      hasStoredContractVersion: true,
    );
    final onboardingStatusController = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: controller,
    );
    await onboardingStatusController.load();
    final themeController = await _createThemeController();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapRequiresOnboarding(
              userId: 'test-user',
            ),
            onboardingStatusController: onboardingStatusController,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider)
      ..go(FeatureRoutes.home.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding.path);
    expect(find.byKey(const ValueKey('app-mode-hybrid')), findsNothing);
    expect(find.text('What should Tio call you?'), findsOneWidget);
    expect(controller.selectedMode, AppMode.hybrid);

    await _completeProfileInputs(tester);

    // #106 keeps the Hybrid Workout decision before the Nutrition block.
    await tester
        .ensureVisible(find.byKey(const ValueKey('workout-intro-later')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('workout-intro-later')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Later skips Workout Profile/Targets, then enters Nutrition Profile.
    await tester.tap(find.byKey(const ValueKey('nutrition-diet-vegetarian')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TioButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nutrition-allergy-none')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TioButton, 'Continue'));
    await tester.pumpAndSettle();

    for (var step = 0;
        step < 8 && find.text('Finish').evaluate().isEmpty;
        step++) {
      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();
    }

    expect(find.text('Finish'), findsOneWidget);
    expect(
      find.textContaining(
          'Finish stays disabled until durable owner persistence'),
      findsOneWidget,
    );
    expect(find.text('Pending'), findsNothing);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();

    expect(controller.selectedMode, AppMode.hybrid);
    expect(onboardingRepository.status, OnboardingStatus.inProgress);
    expect(onboardingStatusController.status, OnboardingStatus.inProgress);
    expect(router.routeInformationProvider.value.uri.path,
        AppRoutes.onboarding.path);
  });

  testWidgets('Settings opens through Profile instead of the Home top bar',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
    );
    final onboardingStatusController = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: controller,
    );
    await onboardingStatusController.load();
    final themeController = await _createThemeController();
    final calendarController = CalendarPreferencesController(
      _SettingsCalendarPreferencesRepository(),
    );
    await calendarController.load();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        calendarPreferencesControllerProvider
            .overrideWith((ref) => calendarController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(userId: 'test-user'),
            onboardingStatusController: onboardingStatusController,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    router.go(FeatureRoutes.home.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Settings'), findsNothing);
    expect(find.byTooltip('Profile'), findsOneWidget);

    tester
        .widget<TioShell>(find.byType(TioShell))
        .onAction(const ShellProfileClicked());
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('profile-settings-action')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('profile-settings-action')));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('settings-app-settings-entry')),
      200.0,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('settings-app-settings-entry')));
    await tester.pumpAndSettle();

    expect(find.text('App Preferences'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('app-settings-app-mode-entry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-settings-theme-entry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('app-settings-units-entry')),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('settings-app-settings-entry')),
      findsOneWidget,
    );
  });

  testWidgets('Settings Units preserves mixed hydration, back and save retry',
      (tester) async {
    final fixture = await _pumpSettingsRoute(tester);
    await tester.tap(find.byKey(const ValueKey('settings-app-settings-entry')));
    await tester.pumpAndSettle();
    final unitsEntry = find.byKey(const ValueKey('app-settings-units-entry'));
    await tester.tap(unitsEntry);
    await tester.pumpAndSettle();

    expect(
      GoRouterState.of(
              tester.element(find.byType(MeasurementUnitsSettingsPage)))
          .uri
          .path,
      AppRoutes.measurementUnitsSettings.path,
    );
    expect(find.text('Units'), findsOneWidget);
    expect(
        tester
            .widget<MeasurementUnitsSettingsPage>(
                find.byType(MeasurementUnitsSettingsPage))
            .initialPreferences,
        _mixedUnits);
    expect(find.byKey(const ValueKey('measurement-units-preset-custom')),
        findsOneWidget);
    final save = find.byKey(const ValueKey('measurement-units-save'));
    expect(tester.widget<TioButton>(save).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('measurement-units-weight-kg')));
    await tester.pump();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AppSettingsPage), findsOneWidget);
    expect(fixture.units.saveCalls, 0);
    expect(fixture.units.preferences, _mixedUnits);

    await tester.tap(unitsEntry);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('measurement-units-weight-kg')));
    await tester.pump();
    final requested = _mixedUnits.copyWith(weightUnit: WeightUnit.kg);
    fixture.units.failNextSave = true;
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('measurement-units-save-error')),
        findsOneWidget);
    expect(find.byType(MeasurementUnitsSettingsPage), findsOneWidget);
    expect(fixture.units.preferences, _mixedUnits);
    expect(
        tester
            .widget<TioMeasurementUnitPreferencesEditor>(
                find.byType(TioMeasurementUnitPreferencesEditor))
            .preferences,
        requested);

    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(fixture.units.saveCalls, 2);
    expect(fixture.units.preferences, requested);
    expect(find.byType(AppSettingsPage), findsOneWidget);
    expect(find.byType(MeasurementUnitsSettingsPage), findsNothing);
    await tester.tap(unitsEntry);
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<MeasurementUnitsSettingsPage>(
                find.byType(MeasurementUnitsSettingsPage))
            .initialPreferences,
        requested);
    expect(tester.widget<TioButton>(save).onPressed, isNull);
  });

  testWidgets('Calendar Settings persists and injects the global week start',
      (tester) async {
    final fixture = await _pumpSettingsRoute(
      tester,
      initialPath: AppRoutes.appSettings.path,
    );

    final calendarEntry =
        find.byKey(const ValueKey('app-settings-calendar-entry'));
    await tester.ensureVisible(calendarEntry);
    await tester.tap(calendarEntry);
    await tester.pumpAndSettle();
    expect(
      GoRouterState.of(tester.element(find.byType(CalendarSettingsPage)))
          .uri
          .path,
      AppRoutes.calendarSettings.path,
    );
    expect(find.byType(CalendarSettingsPage), findsOneWidget);

    // Sunday is the last of seven options, so it sits below the fold on a
    // phone-sized viewport and has to be scrolled to like a real reader would.
    final sunday =
        find.byKey(const ValueKey('calendar-first-day-option-sunday'));
    await tester.scrollUntilVisible(sunday, 200);
    await tester.tap(sunday);
    await tester.pumpAndSettle();
    expect(
      fixture.calendar.firstDayOfWeek,
      FirstDayOfWeekPreference.sunday,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Week starts Sunday'), findsOneWidget);

    fixture.router.go(FeatureRoutes.nutrition.path);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TioDateCalendar>(find.byType(TioDateCalendar))
          .resolvedFirstDayOfWeek,
      DateTime.sunday,
    );

    await fixture.calendar.select(FirstDayOfWeekPreference.monday);
    await tester.pumpAndSettle();
    expect(
      tester.widget<TioDateCalendar>(find.byType(TioDateCalendar))
          .resolvedFirstDayOfWeek,
      DateTime.monday,
    );
  });

  testWidgets('Calendar Settings catches write failures and stays retryable',
      (tester) async {
    final repository = _SettingsCalendarPreferencesRepository()
      ..failNextWrite = true;
    final fixture = await _pumpSettingsRoute(
      tester,
      initialPath: AppRoutes.calendarSettings.path,
      calendarRepository: repository,
    );

    final sunday =
        find.byKey(const ValueKey('calendar-first-day-option-sunday'));
    await tester.scrollUntilVisible(sunday, 200);
    await tester.tap(sunday);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(fixture.calendar.firstDayOfWeek, FirstDayOfWeekPreference.monday);
    expect(fixture.calendar.saveError, isA<StateError>());
    expect(find.byKey(const ValueKey('calendar-first-day-error')), findsOne);
    expect(find.byType(CalendarSettingsPage), findsOneWidget);

    await tester.tap(sunday);
    await tester.pumpAndSettle();

    expect(repository.writeCalls, 2);
    expect(fixture.calendar.firstDayOfWeek, FirstDayOfWeekPreference.sunday);
    expect(fixture.calendar.saveError, isNull);
    expect(
        find.byKey(const ValueKey('calendar-first-day-error')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Calendar Settings does not render a read failure as a save error',
      (tester) async {
    final fixture = await _pumpSettingsRoute(
      tester,
      initialPath: AppRoutes.calendarSettings.path,
      calendarRepository: _SettingsCalendarPreferencesRepository()
        ..readError = true,
    );

    expect(fixture.calendar.firstDayOfWeek, FirstDayOfWeekPreference.monday);
    expect(fixture.calendar.loadError, isA<StateError>());
    expect(fixture.calendar.saveError, isNull);
    expect(
        find.byKey(const ValueKey('calendar-first-day-error')), findsNothing);
  });

  testWidgets('direct Units route retains its existing path and editor',
      (tester) async {
    final fixture = await _pumpSettingsRoute(
      tester,
      initialPath: AppRoutes.measurementUnitsSettings.path,
    );
    expect(fixture.router.routeInformationProvider.value.uri.path,
        '/settings/measurement-units');
    expect(find.byType(MeasurementUnitsSettingsPage), findsOneWidget);
    expect(find.byType(TioMeasurementUnitPreferencesEditor), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(fixture.units.saveCalls, 0);
  });

  testWidgets(
      'Theme uses Appearance sheet and retains direct page compatibility',
      (tester) async {
    final fixture = await _pumpSettingsRoute(
      tester,
      initialPath: AppRoutes.appSettings.path,
    );
    await tester.tap(find.byKey(const ValueKey('app-settings-theme-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(ThemeSelectionBottomSheet), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.byType(ThemeSettingsPage), findsNothing);
    await tester.tap(find.byKey(const ValueKey('theme-option-dark')));
    await tester.pumpAndSettle();
    expect(fixture.theme.selectedMode, TioThemeMode.dark);
    expect(find.byType(ThemeSelectionBottomSheet), findsNothing);
    expect(find.byType(AppSettingsPage), findsOneWidget);

    fixture.router.go(AppRoutes.themeSettings.path);
    await tester.pumpAndSettle();
    expect(fixture.router.routeInformationProvider.value.uri.path,
        '/settings/theme');
    expect(find.byType(ThemeSettingsPage), findsOneWidget);
    expect(
        tester
            .widget<ThemeSettingsPage>(find.byType(ThemeSettingsPage))
            .currentMode,
        TioThemeMode.dark);
  });

  testWidgets('Settings retains Profile and Account owner navigation',
      (tester) async {
    await _pumpSettingsRoute(tester);
    await tester
        .tap(find.byKey(const ValueKey('settings-profile-settings-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSettingsPage), findsOneWidget);
    expect(
        GoRouterState.of(tester.element(find.byType(ProfileSettingsPage)))
            .uri
            .path,
        AppRoutes.profileSettings.path);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester
        .tap(find.byKey(const ValueKey('settings-account-settings-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(AccountSettingsPage), findsOneWidget);
    expect(
        GoRouterState.of(tester.element(find.byType(AccountSettingsPage)))
            .uri
            .path,
        AppRoutes.accountSettings.path);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets('Settings navigates to Health & Goals and Daily Wellness',
      (tester) async {
    await _pumpSettingsRoute(tester);
    await tester
        .tap(find.byKey(const ValueKey('settings-health-goals-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(HealthGoalsSettingsPage), findsOneWidget);
    expect(
        GoRouterState.of(tester.element(find.byType(HealthGoalsSettingsPage)))
            .uri
            .path,
        AppRoutes.healthGoalsSettings.path);

    await tester
        .tap(find.byKey(const ValueKey('health-goals-daily-wellness-entry')));
    await tester.pumpAndSettle();
    expect(find.byType(DailyWellnessSettingsPage), findsOneWidget);
    expect(
        GoRouterState.of(tester.element(find.byType(DailyWellnessSettingsPage)))
            .uri
            .path,
        AppRoutes.dailyWellnessSettings.path);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(HealthGoalsSettingsPage), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
  });

  testWidgets(
      'Settings logout cancel preserves session; confirm signs out to auth',
      (tester) async {
    final fixture = await _pumpSettingsRoute(tester);
    await fixture.hydration
        .write(const HydrationPreferences(defaultGlassSizeMl: 300));
    final logout = find.byKey(const ValueKey('settings-logout-entry'));
    await tester.scrollUntilVisible(logout, 200);
    await tester.tap(logout);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fixture.auth.signOutCalls, 0);
    expect(await fixture.auth.currentSessionState,
        isA<AuthSessionAuthenticated>());
    expect(fixture.hydration.value.defaultGlassSizeMl, 300);
    expect(fixture.router.routeInformationProvider.value.uri.path,
        AppRoutes.settings.path);

    await tester.tap(logout);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await tester.pumpAndSettle();
    expect(fixture.auth.signOutCalls, 1);
    expect(await fixture.auth.currentSessionState,
        isA<AuthSessionUnauthenticated>());
    expect(fixture.hydration.value, const HydrationPreferences());
    expect(fixture.router.routeInformationProvider.value.uri.path,
        AppRoutes.auth.path);
    expect(find.byType(SettingsPage), findsNothing);
  });

  testWidgets('Profile avatar opens the full-screen photo route',
      (tester) async {
    final preference = _MemoryAppModePreference(AppMode.hybrid);
    final controller = AppModeController(preference);
    await controller.load();
    final onboardingRepository = _MemoryOnboardingStatusRepository(
      status: OnboardingStatus.completed,
      hasStoredContractVersion: true,
    );
    final onboardingStatusController = OnboardingStatusController(
      repository: onboardingRepository,
      appModeController: controller,
    );
    await onboardingStatusController.load();
    final themeController = await _createThemeController();
    final container = ProviderContainer(
      overrides: [
        appModeControllerProvider.overrideWith((ref) => controller),
        onboardingStatusControllerProvider
            .overrideWith((ref) => onboardingStatusController),
        onboardingStatusRepositoryProvider
            .overrideWith((ref) => onboardingRepository),
        appThemeControllerProvider.overrideWith((ref) => themeController),
        appSessionBootstrapControllerProvider.overrideWith(
          (ref) => _FixedAppSessionBootstrapController(
            state: const AppSessionBootstrapReady(userId: 'test-user'),
            onboardingStatusController: onboardingStatusController,
          ),
        ),
        profileDataProvider.overrideWith((ref) => Stream.value(
              ProfileSetupData(
                name: 'Tio User',
                gender: ProfileGender.other,
                goals: const {ProfileGoal.keepFit},
                dateOfBirth: DateTime(2000, 1, 1),
                heightCm: 170.0,
                currentWeightKg: 70.0,
                activityLevel: ProfileActivityLevel.active,
                healthConditions: const {},
                avatarUrl: 'https://example.com/avatar.jpg',
              ),
            )),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);
    router.go(AppRoutes.profile.path);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TioApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('profile-avatar-entry')));
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPreviewPage), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-avatar-edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('profile-avatar-delete')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('profile-avatar-download')), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(AvatarPreviewPage), findsNothing);
    expect(find.byKey(const ValueKey('profile-avatar-entry')), findsOneWidget);
  });
}

const _mixedUnits = UnitPreferences(
  weightUnit: WeightUnit.lb,
  heightUnit: HeightUnit.cm,
  distanceUnit: DistanceUnit.mi,
  volumeUnit: VolumeUnit.ml,
);

Future<
    ({
      GoRouter router,
      _SettingsUnitsRepository units,
      _SettingsHydrationRepository hydration,
      _SettingsAuthRepository auth,
      AppThemeController theme,
      CalendarPreferencesController calendar
    })> _pumpSettingsRoute(
  WidgetTester tester, {
  String initialPath = '/settings',
  CalendarPreferencesRepository? calendarRepository,
}) async {
  final mode = AppModeController(_MemoryAppModePreference(AppMode.hybrid));
  await mode.load();
  final onboardingRepository = _MemoryOnboardingStatusRepository(
    status: OnboardingStatus.completed,
    hasStoredContractVersion: true,
  );
  final onboarding = OnboardingStatusController(
    repository: onboardingRepository,
    appModeController: mode,
  );
  await onboarding.load();
  final theme = await _createThemeController();
  final bootstrap = _FixedAppSessionBootstrapController(
    state: const AppSessionBootstrapReady(userId: 'test-user'),
    onboardingStatusController: onboarding,
  );
  final auth = _SettingsAuthRepository(bootstrap.markSignedOut);
  final units = _SettingsUnitsRepository();
  final hydration = _SettingsHydrationRepository();
  final calendar = CalendarPreferencesController(
    calendarRepository ?? _SettingsCalendarPreferencesRepository(),
  );
  await calendar.load();
  addTearDown(auth.dispose);
  final container = ProviderContainer(overrides: [
    supabaseClientProvider.overrideWithValue(null),
    appModeControllerProvider.overrideWith((ref) => mode),
    onboardingStatusControllerProvider.overrideWith((ref) => onboarding),
    onboardingStatusRepositoryProvider
        .overrideWith((ref) => onboardingRepository),
    appThemeControllerProvider.overrideWith((ref) => theme),
    calendarPreferencesControllerProvider.overrideWith((ref) => calendar),
    appSessionBootstrapControllerProvider.overrideWith((ref) => bootstrap),
    authSessionRepositoryProvider.overrideWithValue(auth),
    measurementUnitPreferencesRepositoryProvider.overrideWithValue(units),
    hydrationPreferencesRepositoryProvider.overrideWithValue(hydration),
    profileDataProvider.overrideWith((ref) => Stream.value(ProfileSetupData(
          name: 'Test Member',
          username: 'test_member',
          gender: ProfileGender.other,
          goals: const {},
          dateOfBirth: DateTime(2000, 1, 1),
          heightCm: 170,
          currentWeightKg: 70,
          activityLevel: ProfileActivityLevel.active,
          healthConditions: const {},
          unitPreferences: units.preferences,
        ))),
  ]);
  addTearDown(container.dispose);
  final router = container.read(goRouterProvider)..go(initialPath);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const TioApp(),
  ));
  await tester.pumpAndSettle();
  return (
    router: router,
    units: units,
    hydration: hydration,
    auth: auth,
    theme: theme,
    calendar: calendar,
  );
}

class _SettingsUnitsRepository implements MeasurementUnitPreferencesRepository {
  UnitPreferences preferences = _mixedUnits;
  int saveCalls = 0;
  bool failNextSave = false;

  @override
  Future<void> updateMeasurementUnitPreferences(UnitPreferences next) async {
    saveCalls++;
    if (failNextSave) {
      failNextSave = false;
      throw StateError('Test save failure');
    }
    preferences = next;
  }
}

class _SettingsHydrationRepository implements HydrationPreferencesRepository {
  HydrationPreferences value = const HydrationPreferences();

  @override
  Future<void> clear() async => value = const HydrationPreferences();

  @override
  Future<HydrationPreferences> read() async => value;

  @override
  Future<void> write(HydrationPreferences preferences) async {
    value = preferences;
  }
}

class _SettingsCalendarPreferencesRepository
    implements CalendarPreferencesRepository {
  CalendarPreferences value = const CalendarPreferences();
  int writeCalls = 0;
  bool readError = false;
  bool failNextWrite = false;

  @override
  Future<void> clear() async => value = const CalendarPreferences();

  @override
  Future<CalendarPreferences> read() async {
    if (readError) throw StateError('Test read failure');
    return value;
  }

  @override
  Future<void> write(CalendarPreferences preferences) async {
    writeCalls++;
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('Test write failure');
    }
    value = preferences;
  }
}

class _SettingsAuthRepository extends InMemoryAuthSessionRepository {
  _SettingsAuthRepository(this.onSignedOut)
      : super(
            initialSessionState: const AuthSessionAuthenticated(
          AuthSession(userId: 'test-user'),
        ));

  final VoidCallback onSignedOut;
  int signOutCalls = 0;

  @override
  Future<void> signOut() async {
    signOutCalls++;
    await super.signOut();
    onSignedOut();
  }
}

Future<SystemUiOverlayStyle> _pumpSystemUiOverlay(
  WidgetTester tester, {
  required Brightness platformBrightness,
  required TioThemeConfig config,
}) async {
  tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
  addTearDown(
    tester.platformDispatcher.clearPlatformBrightnessTestValue,
  );
  final preference = _MemoryAppModePreference(AppMode.hybrid);
  final controller = AppModeController(preference);
  await controller.load();
  final onboardingRepository = _MemoryOnboardingStatusRepository(
    status: OnboardingStatus.completed,
    hasStoredContractVersion: true,
  );
  final onboardingStatusController = OnboardingStatusController(
    repository: onboardingRepository,
    appModeController: controller,
  );
  await onboardingStatusController.load();
  final themeController = await _createThemeController();
  final container = ProviderContainer(
    overrides: [
      appModeControllerProvider.overrideWith((ref) => controller),
      onboardingStatusControllerProvider
          .overrideWith((ref) => onboardingStatusController),
      onboardingStatusRepositoryProvider
          .overrideWith((ref) => onboardingRepository),
      appThemeControllerProvider.overrideWith((ref) => themeController),
      appSessionBootstrapControllerProvider.overrideWith(
        (ref) => _FixedAppSessionBootstrapController(
          state: const AppSessionBootstrapReady(userId: 'test-user'),
          onboardingStatusController: onboardingStatusController,
        ),
      ),
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: TioApp(themeConfig: config),
    ),
  );
  await tester.pumpAndSettle();

  return tester
      .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
      )
      .firstWhere(
        (region) => region.value.systemNavigationBarContrastEnforced == false,
      )
      .value;
}

Future<AppThemeController> _createThemeController() async {
  final controller =
      AppThemeController(_MemoryAppThemePreference(TioThemeMode.system));
  await controller.load();
  return controller;
}

Future<void> _completeProfileInputs(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField), 'Tio User');
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(const ValueKey('gender-other'), skipOffstage: false),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  final onboardingController = tester
      .widget<ProfileStepRenderer>(find.byType(ProfileStepRenderer))
      .controller;
  onboardingController
    ..updateProfileDateOfBirth(DateTime(2000, 1, 1))
    ..updateProfileHeight(170.0);
  await tester.pump();

  // Age -> Measurement Units. Defaults are valid, so Continue advances.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();
  expect(find.text('Choose your units'), findsOneWidget);

  // Measurement Units -> Height.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  // Height -> Activity.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(const ValueKey('activity-active'), skipOffstage: false),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  await tester.tap(
    find.byKey(const ValueKey('health-none'), skipOffstage: false),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  // Canonical Body Goal starts with Current Weight after common Profile.
  onboardingController.updateProfileCurrentWeight(70.0);
  await tester.pump();

  // Current Weight -> Goal.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  // Hybrid presents the compatibility loseWeight intent as Fat Loss.
  await tester.tap(
    find.byKey(const ValueKey('goal-intent-loseWeight'), skipOffstage: false),
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  onboardingController.updateProfileTargetWeight(65.0);
  await tester.pump();

  // Target Weight -> Goal Pace.
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();

  onboardingController.updateGoalPaceKgPerWeek(0.5);
  await tester.pump();

  // Goal Pace -> next top-level section (Workout Intro in Hybrid).
  await tester.tap(find.widgetWithText(TioButton, 'Continue'),
      warnIfMissed: false);
  await tester.pumpAndSettle();
}

class _FixedAppSessionBootstrapController
    extends AppSessionBootstrapController {
  _FixedAppSessionBootstrapController({
    required AppSessionBootstrapState state,
    required super.onboardingStatusController,
  })  : fixedState = state,
        super(
          authSessionRepository: InMemoryAuthSessionRepository(),
          onboardingCompletionRepository: null,
        );

  AppSessionBootstrapState fixedState;

  void markSignedOut() {
    fixedState = const AppSessionBootstrapUnauthenticated();
    notifyListeners();
  }

  @override
  AppSessionBootstrapState get state => fixedState;

  @override
  void start() {}
}

class _MemoryAppModePreference implements AppModePreference {
  _MemoryAppModePreference(this.mode);

  AppMode? mode;

  @override
  Future<void> clear() async => mode = null;

  @override
  Future<AppMode?> read() async => mode;

  @override
  Future<void> write(AppMode mode) async => this.mode = mode;
}

class _MemoryAppThemePreference implements AppThemePreference {
  _MemoryAppThemePreference(this.mode);

  TioThemeMode? mode;

  @override
  Future<void> clear() async => mode = null;

  @override
  Future<TioThemeMode?> read() async => mode;

  @override
  Future<void> write(TioThemeMode mode) async => this.mode = mode;
}

class _MemoryOnboardingStatusRepository implements OnboardingStatusRepository {
  _MemoryOnboardingStatusRepository({
    required this.status,
    required this.hasStoredContractVersion,
  });

  OnboardingStatus? status;
  bool hasStoredContractVersion;

  @override
  Future<void> clear() async {
    status = null;
    hasStoredContractVersion = false;
  }

  @override
  Future<void> ensureInitialized() async {
    hasStoredContractVersion = true;
  }

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return OnboardingStatusSnapshot(
      status: status,
      hasStoredContractVersion: hasStoredContractVersion,
    );
  }

  @override
  Future<void> write(OnboardingStatus status) async {
    await ensureInitialized();
    this.status = status;
  }
}

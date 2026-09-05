import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

void main() {
  for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
    for (final width in [390.0, 320.0]) {
      testWidgets('surviving rows preserve layout at $mode/$width',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        Widget app(Widget child) => MaterialApp(
              builder: (context, appChild) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(width == 320 ? 1.6 : 1),
                ),
                child: TioTheme(
                  config: TioThemeConfig(mode: mode),
                  child: appChild!,
                ),
              ),
              home: child,
            );

        await tester.pumpWidget(app(SettingsPage(onAppSettingsPressed: () {})));
        await tester.pumpAndSettle();
        final profile = find.byKey(
          const ValueKey('settings-profile-settings-entry'),
        );
        // Measured on the frozen pre-S0-A source at the same viewport/scaling.
        expect(tester.getSize(profile),
            Size(width - 32, width == 320 ? 298 : 106));
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(app(AppSettingsPage(
          currentMode: AppMode.hybrid,
          currentThemeMode: mode,
          currentFirstDayOfWeek: FirstDayOfWeekPreference.monday,
          onAppModePressed: () {},
          onThemePressed: () {},
          onMeasurementUnitsPressed: () {},
          onCalendarPressed: () {},
        )));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(
              find.byKey(const ValueKey('app-settings-app-mode-entry'))),
          // Re-measured after App Preferences moved from a raw Material Card
          // of ListTiles to TioGroupCard + TioSettingsNavigationRow. The group
          // no longer carries Material's own card margin, so it starts at the
          // page padding (24) instead of 28, and 4dp higher.
          Rect.fromLTRB(24, 80, width - 24, width == 320 ? 209 : 152),
        );
        expect(
          tester
              .getRect(find.byKey(const ValueKey('app-settings-theme-entry'))),
          Rect.fromLTRB(24, width == 320 ? 210 : 153, width - 24,
              width == 320 ? 305 : 225),
        );
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('app-settings-units-entry')),
          100,
        );
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('SettingsPage renders categorized settings entries cleanly',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var profileSettingsTaps = 0;
    var accountSettingsTaps = 0;
    var healthGoalsTaps = 0;
    var appSettingsTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: SettingsPage(
          onProfileSettingsPressed: () => profileSettingsTaps++,
          onAccountSettingsPressed: () => accountSettingsTaps++,
          onHealthGoalsPressed: () => healthGoalsTaps++,
          onAppSettingsPressed: () => appSettingsTaps++,
        ),
      ),
    );

    expect(find.text('ACCOUNT & PROFILE'), findsOneWidget);
    expect(find.text('HEALTH & GOALS'), findsOneWidget);
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('SESSION'), findsOneWidget);

    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('Health & Goals'), findsOneWidget);
    expect(find.text('Daily Wellness targets'), findsOneWidget);
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
    expect(find.text('App Mode, theme, units & calendar'), findsOneWidget);
    expect(find.text('Units'), findsNothing);
    expect(find.byKey(const ValueKey('settings-measurement-units-entry')),
        findsNothing);
    expect(find.byKey(const ValueKey('settings-health-goals-entry')),
        findsOneWidget);
    for (final absent in [
      'Measurement Units',
      'Manage Subscription',
      'Reset Password',
      'Workout Settings',
      'Wear OS / Watch Settings',
      'Nutrition & Diet',
      'About Tio',
      'WORKOUT & WEARABLES',
      'NUTRITION',
      'ABOUT',
      'Theme, sound & haptics, alerts & calendar',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
    expect(find.byType(Divider), findsOneWidget);

    await tester.tap(find.text('Profile Settings'));
    expect(profileSettingsTaps, 1);

    await tester.tap(find.text('Account Settings'));
    expect(accountSettingsTaps, 1);

    await tester.tap(find.text('Health & Goals'));
    expect(healthGoalsTaps, 1);

    await tester.tap(find.text('App Preferences'));
    expect(appSettingsTaps, 1);
  });

  testWidgets(
      'App Preferences exposes real App Mode, Theme, Units and Calendar '
      'actions', (tester) async {
    var modeTaps = 0;
    var themeTaps = 0;
    var unitsTaps = 0;
    var calendarTaps = 0;
    await tester.pumpWidget(MaterialApp(
      home: AppSettingsPage(
        currentMode: AppMode.hybrid,
        currentThemeMode: TioThemeMode.dark,
        currentFirstDayOfWeek: FirstDayOfWeekPreference.sunday,
        onAppModePressed: () => modeTaps++,
        onThemePressed: () => themeTaps++,
        onMeasurementUnitsPressed: () => unitsTaps++,
        onCalendarPressed: () => calendarTaps++,
      ),
    ));
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('App Settings'), findsNothing);
    expect(find.text('Weight, height, distance & volume'), findsOneWidget);
    expect(find.text('Hybrid'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    // The Calendar row reports the current value the way its siblings do.
    expect(find.text('Calendar'), findsOneWidget);
    expect(find.text('Week starts Sunday'), findsOneWidget);
    expect(find.byType(TioSettingsNavigationRow), findsNWidgets(4));
    expect(find.byType(Divider), findsNWidgets(3));

    await tester.tap(find.text('Calendar'));
    expect(calendarTaps, 1);
    await tester.tap(find.text('App Mode'));
    await tester.tap(find.text('Theme'));
    await tester.tap(find.text('Units'));
    expect([modeTaps, themeTaps, unitsTaps], [1, 1, 1]);
  });

  testWidgets('Settings logout requires confirmation and supports cancel',
      (tester) async {
    var logoutCalls = 0;
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TioTheme(child: child!),
      home: SettingsPage(
        onAppSettingsPressed: () {},
        onLogoutPressed: () => logoutCalls++,
      ),
    ));
    final logout = find.byKey(const ValueKey('settings-logout-entry'));
    await tester.scrollUntilVisible(logout, 200);
    await tester.tap(logout);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(logoutCalls, 0);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(logoutCalls, 0);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(logout);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await tester.pumpAndSettle();
    expect(logoutCalls, 1);
    expect(find.byType(AlertDialog), findsNothing);
  });
}

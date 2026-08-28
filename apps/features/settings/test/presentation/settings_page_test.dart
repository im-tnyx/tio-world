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
          onAppModePressed: () {},
          onThemePressed: () {},
          onMeasurementUnitsPressed: () {},
        )));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(
              find.byKey(const ValueKey('app-settings-app-mode-entry'))),
          Rect.fromLTRB(28, 84, width - 28, width == 320 ? 208 : 156),
        );
        expect(
          tester
              .getRect(find.byKey(const ValueKey('app-settings-theme-entry'))),
          Rect.fromLTRB(28, width == 320 ? 209 : 157, width - 28,
              width == 320 ? 295 : 229),
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
    var appSettingsTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: SettingsPage(
          onProfileSettingsPressed: () => profileSettingsTaps++,
          onAccountSettingsPressed: () => accountSettingsTaps++,
          onAppSettingsPressed: () => appSettingsTaps++,
        ),
      ),
    );

    expect(find.text('ACCOUNT & PROFILE'), findsOneWidget);
    expect(find.text('PREFERENCES'), findsOneWidget);
    expect(find.text('SESSION'), findsOneWidget);

    expect(find.text('Profile Settings'), findsOneWidget);
    expect(find.text('Account Settings'), findsOneWidget);
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('Log Out'), findsOneWidget);
    expect(find.text('App Mode, theme & units'), findsOneWidget);
    expect(find.text('Units'), findsNothing);
    expect(find.byKey(const ValueKey('settings-measurement-units-entry')),
        findsNothing);
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

    await tester.tap(find.text('App Preferences'));
    expect(appSettingsTaps, 1);
  });

  testWidgets('App Preferences exposes real App Mode, Theme and Units actions',
      (tester) async {
    var modeTaps = 0;
    var themeTaps = 0;
    var unitsTaps = 0;
    await tester.pumpWidget(MaterialApp(
      home: AppSettingsPage(
        currentMode: AppMode.hybrid,
        currentThemeMode: TioThemeMode.dark,
        onAppModePressed: () => modeTaps++,
        onThemePressed: () => themeTaps++,
        onMeasurementUnitsPressed: () => unitsTaps++,
      ),
    ));
    expect(find.text('App Preferences'), findsOneWidget);
    expect(find.text('App Settings'), findsNothing);
    expect(find.text('Weight, height, distance & volume'), findsOneWidget);
    expect(find.text('Hybrid'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(find.byType(ListTile), findsNWidgets(3));
    expect(find.byType(Divider), findsNWidgets(2));
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

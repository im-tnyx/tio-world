import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';
import 'package:tio_shared/shared.dart';

/// Screen-level coverage for App Preferences after its migration to the
/// canonical grouped Settings surface.
///
/// This is the screen the owner actually reported: it was the last production
/// surface composing a raw Material `Card` of raw `ListTile`s while every other
/// grouped Settings and Nutrition surface used `TioGroupCard` +
/// `TioSettingsNavigationRow`.
void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    AppMode currentMode = AppMode.hybrid,
    TioThemeMode currentThemeMode = TioThemeMode.dark,
    FirstDayOfWeekPreference currentFirstDayOfWeek =
        FirstDayOfWeekPreference.monday,
    TioThemeMode themeMode = TioThemeMode.light,
    VoidCallback? onAppModePressed,
    VoidCallback? onThemePressed,
    VoidCallback? onMeasurementUnitsPressed,
    VoidCallback? onCalendarPressed,
    double textScale = 1,
    Size surfaceSize = const Size(390, 1200),
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: themeMode),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: AppSettingsPage(
          currentMode: currentMode,
          currentThemeMode: currentThemeMode,
          currentFirstDayOfWeek: currentFirstDayOfWeek,
          onAppModePressed: onAppModePressed ?? () {},
          onThemePressed: onThemePressed ?? () {},
          onMeasurementUnitsPressed: onMeasurementUnitsPressed ?? () {},
          onCalendarPressed: onCalendarPressed ?? () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  const appModeKey = ValueKey('app-settings-app-mode-entry');
  const themeKey = ValueKey('app-settings-theme-entry');
  const unitsKey = ValueKey('app-settings-units-entry');
  const calendarKey = ValueKey('app-settings-calendar-entry');

  group('canonical surface', () {
    testWidgets('renders exactly the four navigation rows in one group',
        (tester) async {
      await pumpPage(tester);

      expect(find.byType(TioGroupCard), findsOneWidget);
      expect(find.byType(TioSettingsNavigationRow), findsNWidgets(4));
      expect(find.byType(TioSettingsLeadingIcon), findsNWidgets(4));
    });

    testWidgets('no raw Material card or list tile remains', (tester) async {
      await pumpPage(tester);

      // The whole point of the migration: the screen must consume the core
      // grouped surface instead of rebuilding it from framework primitives.
      expect(find.byType(Card), findsNothing);
      expect(find.byType(ListTile), findsNothing);
    });

    testWidgets('the four stable keys survive and resolve to the row type',
        (tester) async {
      await pumpPage(tester);

      for (final key in [appModeKey, themeKey, unitsKey, calendarKey]) {
        expect(find.byKey(key), findsOneWidget, reason: '$key');
        expect(
          tester.widget(find.byKey(key)),
          isA<TioSettingsNavigationRow>(),
          reason: '$key',
        );
      }
    });
  });

  group('content', () {
    testWidgets('titles and supporting text are unchanged', (tester) async {
      await pumpPage(
        tester,
        currentMode: AppMode.hybrid,
        currentThemeMode: TioThemeMode.dark,
      );

      expect(find.text('App Preferences'), findsOneWidget);
      expect(find.text('App Mode'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
      expect(find.text('Units'), findsOneWidget);
      expect(find.text('Hybrid'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(
        find.text('Weight, height, distance & volume'),
        findsOneWidget,
      );
    });

    testWidgets('supporting text follows the live mode and theme',
        (tester) async {
      await pumpPage(
        tester,
        currentMode: AppMode.nutrition,
        currentThemeMode: TioThemeMode.system,
      );

      expect(find.text('Nutrition'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });
  });

  group('navigation callbacks', () {
    testWidgets('App Mode row fires its callback', (tester) async {
      var taps = 0;
      await pumpPage(tester, onAppModePressed: () => taps++);

      await tester.tap(find.byKey(appModeKey));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('Theme row fires its callback', (tester) async {
      var taps = 0;
      await pumpPage(tester, onThemePressed: () => taps++);

      await tester.tap(find.byKey(themeKey));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('Units row fires its callback', (tester) async {
      var taps = 0;
      await pumpPage(tester, onMeasurementUnitsPressed: () => taps++);

      await tester.tap(find.byKey(unitsKey));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('Calendar row fires its callback', (tester) async {
      var taps = 0;
      await pumpPage(tester, onCalendarPressed: () => taps++);

      await tester.tap(find.byKey(calendarKey));
      await tester.pumpAndSettle();

      expect(taps, 1);
    });

    testWidgets('tapping one row does not fire the others', (tester) async {
      var mode = 0;
      var theme = 0;
      var units = 0;
      var calendar = 0;
      await pumpPage(
        tester,
        onAppModePressed: () => mode++,
        onThemePressed: () => theme++,
        onMeasurementUnitsPressed: () => units++,
        onCalendarPressed: () => calendar++,
      );

      await tester.tap(find.byKey(themeKey));
      await tester.pumpAndSettle();

      expect([mode, theme, units, calendar], [0, 1, 0, 0]);
    });

    testWidgets('the Calendar row reports the current week start',
        (tester) async {
      await pumpPage(tester);
      expect(find.text('Week starts Monday'), findsOneWidget);

      await pumpPage(
        tester,
        currentFirstDayOfWeek: FirstDayOfWeekPreference.sunday,
      );
      expect(find.text('Week starts Sunday'), findsOneWidget);
      expect(find.text('Week starts Monday'), findsNothing);
    });
  });

  group('rendering', () {
    testWidgets('renders in light mode without exception', (tester) async {
      await pumpPage(tester);

      expect(tester.takeException(), isNull);
      expect(find.byType(TioGroupCard), findsOneWidget);
    });

    testWidgets('renders in dark mode without exception', (tester) async {
      await pumpPage(tester, themeMode: TioThemeMode.dark);

      expect(tester.takeException(), isNull);
      expect(find.byType(TioGroupCard), findsOneWidget);
    });

    testWidgets('renders at large text scale without overflow', (tester) async {
      await pumpPage(
        tester,
        textScale: 1.6,
        surfaceSize: const Size(390, 1600),
      );

      expect(tester.takeException(), isNull);
      expect(find.byType(TioSettingsNavigationRow), findsNWidgets(4));
      expect(find.text('App Mode'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
    });
  });
}

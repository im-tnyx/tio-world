import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  testWidgets('HealthGoalsSettingsPage renders cleanly and navigates to Daily Wellness',
      (tester) async {
    var dailyWellnessTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: HealthGoalsSettingsPage(
          onDailyWellnessPressed: () => dailyWellnessTaps++,
        ),
      ),
    );

    expect(find.text('Health & Goals'), findsOneWidget);
    expect(find.text('Manage your daily wellness and lifestyle targets.'),
        findsOneWidget);
    expect(find.text('DAILY TARGETS'), findsOneWidget);
    expect(find.text('Daily Wellness'), findsOneWidget);
    expect(find.text('Steps, water, sleep & schedule'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('health-goals-daily-wellness-entry')),
        findsOneWidget);

    // Verify absence of fake Body & Weight placeholder rows
    for (final absent in [
      'Body & Weight',
      'Body Goal',
      'Weight Goal',
      'Target Weight',
      'Current Weight',
      'Glass Size',
      'Nutrition Targets',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }

    await tester.tap(find.byKey(const ValueKey('health-goals-daily-wellness-entry')));
    expect(dailyWellnessTaps, 1);
  });

  for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
    for (final width in [390.0, 320.0]) {
      testWidgets('HealthGoalsSettingsPage renders at $mode/$width',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          MaterialApp(
            builder: (context, appChild) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(width == 320 ? 1.6 : 1),
              ),
              child: TioTheme(
                config: TioThemeConfig(mode: mode),
                child: appChild!,
              ),
            ),
            home: HealthGoalsSettingsPage(onDailyWellnessPressed: () {}),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const ValueKey('health-goals-daily-wellness-entry')),
            findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}

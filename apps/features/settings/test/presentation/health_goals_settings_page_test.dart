import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  testWidgets(
      'HealthGoalsSettingsPage renders cleanly and navigates to Daily Wellness and Body & Weight',
      (tester) async {
    var dailyWellnessTaps = 0;
    var bodyWeightTaps = 0;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) =>
            TioTheme(child: child ?? const SizedBox.shrink()),
        home: HealthGoalsSettingsPage(
          onDailyWellnessPressed: () => dailyWellnessTaps++,
          onBodyWeightPressed: () => bodyWeightTaps++,
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
    expect(find.text('Body & Weight'), findsOneWidget);
    expect(find.text('Current weight, Body Goal & pace'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('health-goals-body-weight-entry')),
        findsOneWidget);

    // Verify absence of fake field-level placeholder rows -- Body & Weight's
    // own fields must only appear on its detail page, not flattened here.
    for (final absent in [
      'Body Goal',
      'Weight Goal',
      'Target Weight',
      'Current Weight',
      'Glass Size',
      'Nutrition Targets',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }

    await tester
        .tap(find.byKey(const ValueKey('health-goals-daily-wellness-entry')));
    expect(dailyWellnessTaps, 1);

    await tester
        .tap(find.byKey(const ValueKey('health-goals-body-weight-entry')));
    expect(bodyWeightTaps, 1);
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
            home: HealthGoalsSettingsPage(
            onDailyWellnessPressed: () {},
            onBodyWeightPressed: () {},
          ),
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

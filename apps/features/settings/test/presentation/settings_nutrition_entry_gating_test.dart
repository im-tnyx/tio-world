import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

/// Settings owns only the presentation gate for the Nutrition entry. The
/// capability decision itself is supplied by app composition from canonical
/// App Mode, so these tests prove the gate is honoured exactly and that
/// Settings never renders a disabled or empty Nutrition section.
void main() {
  Widget host(Widget child) => MaterialApp(
        builder: (context, appChild) =>
            TioTheme(child: appChild ?? const SizedBox.shrink()),
        home: child,
      );

  testWidgets('Nutrition section is absent when the capability gate is off',
      (tester) async {
    await tester.pumpWidget(host(SettingsPage(
      onAppSettingsPressed: () {},
      onNutritionPressed: () {},
    )));

    expect(
        find.byKey(const ValueKey('settings-nutrition-entry')), findsNothing);
    expect(find.text('NUTRITION'), findsNothing);
    expect(find.text('Nutrition & Diet'), findsNothing);
  });

  testWidgets('showNutritionSection defaults to off', (tester) async {
    await tester.pumpWidget(host(SettingsPage(onAppSettingsPressed: () {})));

    expect(
        find.byKey(const ValueKey('settings-nutrition-entry')), findsNothing);
  });

  testWidgets('Nutrition section renders and routes when the gate is on',
      (tester) async {
    var nutritionTaps = 0;

    await tester.pumpWidget(host(SettingsPage(
      onAppSettingsPressed: () {},
      showNutritionSection: true,
      onNutritionPressed: () => nutritionTaps++,
    )));

    expect(
      find.byKey(const ValueKey('settings-nutrition-entry')),
      findsOneWidget,
    );
    expect(find.text('NUTRITION'), findsOneWidget);
    expect(find.text('Nutrition & Diet'), findsOneWidget);
    expect(find.text('Diet Type, allergies & restrictions'), findsOneWidget);

    await tester.tap(find.text('Nutrition & Diet'));
    expect(nutritionTaps, 1);
  });

  testWidgets('Nutrition sits between Health & Goals and Preferences',
      (tester) async {
    await tester.pumpWidget(host(SettingsPage(
      onAppSettingsPressed: () {},
      showNutritionSection: true,
      onNutritionPressed: () {},
    )));

    final healthGoals = tester.getTopLeft(find.text('HEALTH & GOALS')).dy;
    final nutrition = tester.getTopLeft(find.text('NUTRITION')).dy;
    final preferences = tester.getTopLeft(find.text('PREFERENCES')).dy;

    expect(nutrition, greaterThan(healthGoals));
    expect(preferences, greaterThan(nutrition));
  });

  testWidgets('turning the gate off removes the section without side effects',
      (tester) async {
    await tester.pumpWidget(host(SettingsPage(
      onAppSettingsPressed: () {},
      showNutritionSection: true,
      onNutritionPressed: () {},
    )));
    expect(
      find.byKey(const ValueKey('settings-nutrition-entry')),
      findsOneWidget,
    );

    await tester.pumpWidget(host(SettingsPage(
      onAppSettingsPressed: () {},
      onNutritionPressed: () {},
    )));
    await tester.pumpAndSettle();

    expect(
        find.byKey(const ValueKey('settings-nutrition-entry')), findsNothing);
    // Every other Settings capability survives the gate flip untouched.
    expect(
      find.byKey(const ValueKey('settings-health-goals-entry')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('settings-app-settings-entry')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

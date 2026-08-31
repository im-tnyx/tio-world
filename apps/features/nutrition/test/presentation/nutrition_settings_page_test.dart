import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// The Nutrition Settings hub is a launcher only. V1 must expose exactly the
/// one capability that is implemented, and must not advertise unbuilt ones as
/// placeholder rows.
void main() {
  Widget host(Widget child) => MaterialApp(
        builder: (context, appChild) =>
            TioTheme(child: appChild ?? const SizedBox.shrink()),
        home: child,
      );

  testWidgets('hub exposes only the Nutrition Profile entry', (tester) async {
    await tester.pumpWidget(
      host(NutritionSettingsPage(onNutritionProfilePressed: () {})),
    );

    expect(
      find.byKey(const ValueKey('nutrition-settings-profile-entry')),
      findsOneWidget,
    );
    expect(find.text('Nutrition Profile'), findsOneWidget);
    expect(find.text('Diet Type, allergies & restrictions'), findsOneWidget);

    for (final absent in [
      'Nutrition Targets',
      'Daily Targets',
      'Eating Style',
      'Nutrition Approach',
      'Meal Diary',
      'Diet Plan',
      'Coming soon',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
  });

  testWidgets('tapping the entry delegates navigation upward', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      host(NutritionSettingsPage(onNutritionProfilePressed: () => taps++)),
    );

    await tester.tap(find.text('Nutrition Profile'));
    expect(taps, 1);
  });

  testWidgets('hub renders cleanly in both themes and at small width',
      (tester) async {
    tester.view.physicalSize = const Size(320, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final mode in [TioThemeMode.light, TioThemeMode.dark]) {
      await tester.pumpWidget(MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.6),
          ),
          child: TioTheme(
            config: TioThemeConfig(mode: mode),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: NutritionSettingsPage(onNutritionProfilePressed: () {}),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$mode');
    }
  });
}

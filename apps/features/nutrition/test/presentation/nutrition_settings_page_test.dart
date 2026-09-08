import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// The Nutrition Settings hub is a launcher only. It must expose exactly the
/// capabilities that are implemented, and must not advertise unbuilt ones as
/// placeholder rows.
void main() {
  Widget host(Widget child) => MaterialApp(
        builder: (context, appChild) =>
            TioTheme(child: appChild ?? const SizedBox.shrink()),
        home: child,
      );

  Widget hub({
    VoidCallback? onProfile,
    VoidCallback? onTargets,
    VoidCallback? onMealDiary,
  }) =>
      NutritionSettingsPage(
        onNutritionProfilePressed: onProfile ?? () {},
        onNutritionTargetsPressed: onTargets ?? () {},
        onMealDiarySettingsPressed: onMealDiary ?? () {},
      );

  testWidgets('hub exposes the implemented capabilities only', (tester) async {
    await tester.pumpWidget(host(hub()));

    expect(
      find.byKey(const ValueKey('nutrition-settings-profile-entry')),
      findsOneWidget,
    );
    expect(find.text('Nutrition Profile'), findsOneWidget);
    expect(find.text('Diet Type, allergies & restrictions'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('nutrition-settings-targets-entry')),
      findsOneWidget,
    );
    expect(find.text('Nutrition Targets'), findsOneWidget);
    expect(find.text('Calories, protein, carbs, fat & fiber'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('nutrition-settings-meal-diary-entry')),
      findsOneWidget,
    );
    expect(find.text('Meal Diary Settings'), findsOneWidget);
    expect(find.text('Diary-specific logging preferences'), findsOneWidget);

    // Capabilities without an approved implementation stay absent rather than
    // appearing as inert rows.
    for (final absent in [
      'Additional Nutrition',
      'Eating Style',
      'Nutrition Approach',
      'Diet Plan',
      'Calories goal by meal',
      'Coming soon',
      // The hub links to Meal Diary Settings; it does not restate the
      // preferences that page owns.
      'Show meal times',
      'Meal Notes',
      'Meal Reminders',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }
  });

  testWidgets('each entry delegates navigation upward', (tester) async {
    var profileTaps = 0;
    var targetTaps = 0;
    var mealDiaryTaps = 0;

    await tester.pumpWidget(host(hub(
      onProfile: () => profileTaps++,
      onTargets: () => targetTaps++,
      onMealDiary: () => mealDiaryTaps++,
    )));

    await tester.tap(find.text('Nutrition Profile'));
    expect([profileTaps, targetTaps, mealDiaryTaps], [1, 0, 0]);

    await tester.tap(find.text('Nutrition Targets'));
    expect([profileTaps, targetTaps, mealDiaryTaps], [1, 1, 0]);

    await tester.tap(find.text('Meal Diary Settings'));
    expect([profileTaps, targetTaps, mealDiaryTaps], [1, 1, 1]);
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
        home: hub(),
      ));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: '$mode');
    }
  });
}

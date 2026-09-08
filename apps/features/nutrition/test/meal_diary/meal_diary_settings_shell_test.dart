import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

Widget _host(
  Widget child, {
  TioThemeMode mode = TioThemeMode.light,
  double textScale = 1,
}) {
  return MaterialApp(
    builder: (context, appChild) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: TioTheme(
        config: TioThemeConfig(mode: mode),
        child: appChild ?? const SizedBox.shrink(),
      ),
    ),
    home: child,
  );
}

void main() {
  testWidgets('More exposes only the Meal Diary Settings action',
      (tester) async {
    var opens = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        Scaffold(
          appBar: AppBar(
            actions: [
              MealDiaryMoreMenu(
                onMealDiarySettingsPressed: () => opens++,
              ),
            ],
          ),
        ),
      ),
    );

    final more = find.byKey(const ValueKey('meal-diary-more-menu'));
    final moreTooltip = find.byTooltip('More');
    expect(more, findsOneWidget);
    expect(moreTooltip, findsOneWidget);
    expect(tester.getSize(more).width,
        greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(tester.getSize(more).height,
        greaterThanOrEqualTo(kMinInteractiveDimension));
    expect(
      tester.getSemantics(moreTooltip),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
        hasExpandedState: true,
        tooltip: 'More',
      ),
    );

    await tester.tap(more);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-settings-menu-item')),
      findsOneWidget,
    );
    expect(find.text('Meal Diary Settings'), findsOneWidget);

    await tester.tap(find.text('Meal Diary Settings'));
    await tester.pumpAndSettle();
    expect(opens, 1);
    semantics.dispose();
  });

  testWidgets('Settings shell exposes only the Meal Categories row',
      (tester) async {
    var categoryTaps = 0;
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _host(
        MealDiarySettingsPage(
          onMealCategoriesPressed: () => categoryTaps++,
        ),
      ),
    );

    final categories =
        find.byKey(const ValueKey('meal-diary-settings-categories-entry'));
    expect(find.text('Meal Diary Settings'), findsOneWidget);
    expect(find.text('Meal Categories'), findsOneWidget);
    expect(find.text('Manage meal categories'), findsOneWidget);
    expect(categories, findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
    expect(
      tester.getSemantics(categories),
      matchesSemantics(
        // The row merges its title and supporting text into one node, so the
        // announced label is both lines rather than the title alone.
        label: 'Meal Categories\nManage meal categories',
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );

    for (final absent in [
      'Show meal times',
      'Meal Notes',
      'Show note preview',
      'Meal Reminders',
      'Restore Defaults',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }

    await tester.tap(categories);
    expect(categoryTaps, 1);
    semantics.dispose();
  });

  testWidgets('child destination is a title and back boundary only',
      (tester) async {
    await tester.pumpWidget(_host(const MealCategoriesDestinationPage()));

    expect(find.text('Meal Categories'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(TioSettingsNavigationRow), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  for (final testCase in const [
    (name: 'Light', mode: TioThemeMode.light, expected: TioColors.light),
    (name: 'Dark', mode: TioThemeMode.dark, expected: TioColors.dark),
    (name: 'OLED', mode: TioThemeMode.oled, expected: TioColors.oled),
    (name: 'System-dark', mode: TioThemeMode.system, expected: TioColors.dark),
  ]) {
    testWidgets('${testCase.name} inherits theme at compact width',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(
        tester.platformDispatcher.clearPlatformBrightnessTestValue,
      );

      await tester.pumpWidget(
        _host(
          MealDiarySettingsPage(onMealCategoriesPressed: () {}),
          mode: testCase.mode,
          textScale: 1.6,
        ),
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(
        find.byKey(const ValueKey('meal-diary-settings-page')),
      );
      expect(scaffold.backgroundColor, testCase.expected.background);
      expect(tester.takeException(), isNull, reason: testCase.name);
    });
  }
}

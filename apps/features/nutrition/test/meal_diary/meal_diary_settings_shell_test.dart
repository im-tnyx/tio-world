import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

Widget _host(
  Widget child, {
  TioThemeMode mode = TioThemeMode.light,
  double textScale = 1,
}) {
  return ProviderScope(
    child: MaterialApp(
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
    ),
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

  testWidgets('the open menu stays inside the screen at the right edge',
      (tester) async {
    // The trigger lives at the far right of the top bar, which is exactly
    // where a menu gets clamped flush against the edge and its rounded corner
    // reads as clipped. This pins the inset that keeps the card off the edge.
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _host(
        Scaffold(
          appBar: AppBar(
            actions: [MealDiaryMoreMenu(onMealDiarySettingsPressed: () {})],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('meal-diary-more-menu')));
    await tester.pumpAndSettle();

    final card = tester.getRect(
      find.byKey(const ValueKey('meal-diary-settings-menu-card')),
    );
    expect(card.left, greaterThanOrEqualTo(0));
    expect(
      card.right,
      lessThanOrEqualTo(390 - TioSpacing.sm),
      reason: 'the card must not sit flush against the right screen edge',
    );
    expect(card.top, greaterThan(0));
  });

  testWidgets('a dismissing tap does not reach the control underneath',
      (tester) async {
    // `MenuAnchor.consumeOutsideTap` defaults to false, which makes the tap
    // that closes the menu also press whatever is beneath it — on the Diary
    // that is a date cell or the logging action, so closing the menu would
    // silently change the selected day. The assertion that matters is the
    // negative one: the underlying callback must not fire.
    var underlyingTaps = 0;
    var settingsTaps = 0;

    await tester.pumpWidget(
      _host(
        Scaffold(
          appBar: AppBar(
            actions: [
              MealDiaryMoreMenu(
                onMealDiarySettingsPressed: () => settingsTaps++,
              ),
            ],
          ),
          body: Center(
            child: ElevatedButton(
              key: const ValueKey('underlying-control'),
              onPressed: () => underlyingTaps++,
              child: const Text('Underlying'),
            ),
          ),
        ),
      ),
    );

    final more = find.byKey(const ValueKey('meal-diary-more-menu'));
    final underlying = find.byKey(const ValueKey('underlying-control'));

    // Baseline: the control is genuinely tappable, so a later zero is a real
    // result rather than a broken target.
    await tester.tap(underlying);
    await tester.pumpAndSettle();
    expect(underlyingTaps, 1);

    await tester.tap(more);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('meal-diary-settings-menu-item')),
      findsOneWidget,
    );

    // One tap outside, on the live control.
    await tester.tap(underlying);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('meal-diary-settings-menu-item')),
      findsNothing,
      reason: 'the outside tap dismisses the menu',
    );
    expect(
      underlyingTaps,
      1,
      reason: 'and it must not also press the control it landed on',
    );

    // The control still works once the menu is gone.
    await tester.tap(underlying);
    await tester.pumpAndSettle();
    expect(underlyingTaps, 2);
    expect(settingsTaps, 0);
  });

  testWidgets('Settings shell exposes categories and N14 display preferences',
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
    await tester.pumpAndSettle();

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

    for (final present in [
      'Show meal times',
      'Meal Notes',
      'Show note preview',
    ]) {
      expect(find.text(present), findsOneWidget, reason: present);
    }

    for (final absent in [
      'Meal Reminders',
      'Restore Defaults',
    ]) {
      expect(find.text(absent), findsNothing, reason: absent);
    }

    await tester.tap(categories);
    expect(categoryTaps, 1);
    semantics.dispose();
  });

  testWidgets('child destination keeps its title and back affordance',
      (tester) async {
    // The empty-boundary assertions this test used to make were retired when
    // TNYX-67 Slice C filled the destination. What still belongs to the shell
    // is the chrome; the management behavior has its own test file.
    await tester.pumpWidget(
      _host(
        MealCategoriesDestinationPage(
          repository: InMemoryMealCategoriesRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Meal Categories'), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
    expect(find.byType(TioSettingsNavigationRow), findsNothing);
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

import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// A fixed clock, for the same reason the calendar tests use one: "today" has
/// to mean the same day on every run.
final _now = DateTime(2026, 8, 20, 10, 30);
final _today = DateTime(2026, 8, 20);
final _yesterday = DateTime(2026, 8, 19);

const _addAction = ValueKey('meal-diary-add-food-action');
const _sheet = ValueKey('meal-diary-add-food-sheet');
const _sheetClose = ValueKey('meal-diary-add-food-close');
const _quickAddRow = ValueKey('add-food-quick-add');
const _editor = ValueKey('quick-add-editor');
const _logMeal = ValueKey('quick-add-log-meal');
const _emptyDayNote = ValueKey('meal-diary-empty-day-note');

Future<MealDiaryDateController> _pump(
  WidgetTester tester, {
  int? resolvedFirstDayOfWeek,
}) async {
  final controller = MealDiaryDateController(clock: () => _now);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealDiaryDateControllerProvider.overrideWith((ref) => controller),
      ],
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: MealDiaryPage(resolvedFirstDayOfWeek: resolvedFirstDayOfWeek),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return controller;
}

Future<void> _openAddFood(WidgetTester tester) async {
  await tester.tap(find.byKey(_addAction));
  await tester.pumpAndSettle();
}

Future<void> _openQuickAdd(WidgetTester tester) async {
  await _openAddFood(tester);
  await tester.tap(find.byKey(_quickAddRow));
  await tester.pumpAndSettle();
}

Future<void> _type(WidgetTester tester, ValueKey<String> field, String text) async {
  await tester.enterText(find.byKey(field), text);
  await tester.pumpAndSettle();
}

String _fieldText(WidgetTester tester, ValueKey<String> field) =>
    tester.widget<TioInput>(find.byKey(field)).controller!.text;

String? _fieldError(WidgetTester tester, ValueKey<String> field) =>
    tester.widget<TioInput>(find.byKey(field)).errorText;

void main() {
  group('Meal Diary logging entry', () {
    testWidgets('the diary offers a labelled add-food affordance',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      expect(find.byKey(_addAction), findsOne);
      expect(
        tester.getSemantics(find.byKey(_addAction)),
        matchesSemantics(
          isButton: true,
          isEnabled: true,
          hasEnabledState: true,
          hasTapAction: true,
          label: 'Add food',
        ),
      );

      handle.dispose();
    });

    testWidgets('tapping it opens the Add Food sheet', (tester) async {
      await _pump(tester);

      expect(find.byKey(_sheet), findsNothing);
      await _openAddFood(tester);
      expect(find.byKey(_sheet), findsOne);
    });

    testWidgets('the calendar still selects dates with the affordance present',
        (tester) async {
      final controller = await _pump(tester);

      await tester.tap(find.byKey(ValueKey(_yesterday)));
      await tester.pumpAndSettle();

      expect(controller.selectedDate, _yesterday);
    });

    testWidgets('the future stays unreachable', (tester) async {
      final controller = await _pump(tester);
      final tomorrow = DateTime(2026, 8, 21);

      await tester.tap(find.byKey(ValueKey(tomorrow)));
      await tester.pumpAndSettle();

      expect(controller.selectedDate, _today);
      expect(controller.maxDate, _today);
    });

    testWidgets('the app-global week start still reaches the calendar',
        (tester) async {
      await _pump(tester, resolvedFirstDayOfWeek: DateTime.wednesday);

      expect(
        tester
            .widget<TioDateCalendar>(find.byType(TioDateCalendar))
            .resolvedFirstDayOfWeek,
        DateTime.wednesday,
      );
      // The affordance did not displace the forwarding.
      expect(find.byKey(_addAction), findsOne);
    });

    testWidgets('the affordance steps aside for the expanded month grid',
        (tester) async {
      await _pump(tester);
      expect(find.byKey(_addAction), findsOne);

      await tester.tap(find.byKey(const ValueKey('tio-date-calendar-handle')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('tio-date-calendar-month-pager')),
        findsOne,
      );
      expect(find.byKey(_addAction), findsNothing);

      await tester.tap(find.byKey(const ValueKey('tio-date-calendar-handle')));
      await tester.pumpAndSettle();
      expect(find.byKey(_addAction), findsOne);
    });

    testWidgets('opening and dismissing Add Food leaves the day alone',
        (tester) async {
      final controller = await _pump(tester);

      controller.select(_yesterday);
      await tester.pumpAndSettle();

      await _openAddFood(tester);
      expect(controller.selectedDate, _yesterday);

      await tester.tap(find.byKey(_sheetClose));
      await tester.pumpAndSettle();

      expect(find.byKey(_sheet), findsNothing);
      expect(controller.selectedDate, _yesterday);
      // Nothing was logged, and the diary still says so.
      expect(find.byKey(_emptyDayNote), findsOne);
    });
  });

  group('Add Food sheet', () {
    testWidgets('Quick Add is the one path that works', (tester) async {
      await _pump(tester);
      await _openAddFood(tester);

      await tester.tap(find.byKey(_quickAddRow));
      await tester.pumpAndSettle();

      expect(find.byKey(_editor), findsOne);
    });

    testWidgets('the future paths are shown as unavailable, not as working',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _openAddFood(tester);

      const future = <(ValueKey<String>, String)>[
        (
          ValueKey('add-food-ai-text'),
          'Describe a meal in your own words. Not available yet.',
        ),
        (
          ValueKey('add-food-photo'),
          'Take a photo of your food. Not available yet.',
        ),
        (
          ValueKey('add-food-search'),
          'Search the food database. Not available yet.',
        ),
      ];

      for (final (key, label) in future) {
        expect(find.byKey(key), findsOne, reason: '$key should be visible');
        // Shown, disabled, and saying why in words — no tap action at all, so
        // there is nothing for assistive technology to invoke either.
        expect(
          tester.getSemantics(find.byKey(key)),
          matchesSemantics(
            isButton: true,
            hasEnabledState: true,
            isEnabled: false,
            label: label,
          ),
          reason: '$key must present itself as unavailable',
        );

        // Tapping does nothing at all: no navigation, no sheet teardown.
        await tester.tap(find.byKey(key));
        await tester.pumpAndSettle();
        expect(find.byKey(_sheet), findsOne);
        expect(find.byKey(_editor), findsNothing);
      }

      handle.dispose();
    });
  });

  group('Quick Add manual nutrition editor', () {
    testWidgets('it opens on the day the diary is showing', (tester) async {
      final controller = await _pump(tester);

      controller.select(_yesterday);
      await tester.pumpAndSettle();
      await _openQuickAdd(tester);

      const dateField = ValueKey('quick-add-selected-date');
      expect(_fieldText(tester, dateField), contains('August 19, 2026'));
      // Not today, which is the whole point of carrying the selection.
      expect(_fieldText(tester, dateField), isNot(contains('August 20')));
      // Shown, not editable: TNYX-114 owns date and time.
      expect(tester.widget<TioInput>(find.byKey(dateField)).enabled, isFalse);
      expect(controller.selectedDate, _yesterday);
    });

    testWidgets('it renders the bounded field set', (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      for (final key in const [
        ValueKey('quick-add-meal-name'),
        ValueKey('quick-add-calories'),
        ValueKey('quick-add-protein'),
        ValueKey('quick-add-carbs'),
        ValueKey('quick-add-fat'),
        ValueKey('quick-add-fiber'),
        ValueKey('quick-add-selected-date'),
      ]) {
        expect(find.byKey(key), findsOne, reason: '$key should be rendered');
      }
    });

    testWidgets('a negative value is rejected in words', (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      const calories = ValueKey('quick-add-calories');
      await _type(tester, calories, '-5');

      expect(_fieldError(tester, calories), 'Calories cannot be negative.');
      expect(find.text('Calories cannot be negative.'), findsOne);

      // And it clears once the value is valid again.
      await _type(tester, calories, '500');
      expect(_fieldError(tester, calories), isNull);
    });

    testWidgets('a value that is not a number is rejected', (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      const protein = ValueKey('quick-add-protein');
      await _type(tester, protein, '1.2.3');

      expect(_fieldError(tester, protein), 'Enter a number.');
      expect(find.text('Enter a number.'), findsOne);
    });

    testWidgets('letters never reach the field at all', (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      const fat = ValueKey('quick-add-fat');
      await _type(tester, fat, '1e400abc');

      expect(_fieldText(tester, fat), '1400');
      expect(_fieldError(tester, fat), isNull);
    });

    testWidgets('a blank optional field is absent, not an error and not zero',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      for (final key in const [
        ValueKey('quick-add-protein'),
        ValueKey('quick-add-carbs'),
        ValueKey('quick-add-fat'),
        ValueKey('quick-add-fiber'),
      ]) {
        expect(_fieldText(tester, key), isEmpty);
        expect(_fieldError(tester, key), isNull);
      }
    });

    testWidgets('Log Meal is present, disabled, and says why', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _openQuickAdd(tester);

      expect(find.byKey(_logMeal), findsOne);
      expect(tester.widget<TioButton>(find.byKey(_logMeal)).onPressed, isNull);

      expect(
        tester.getSemantics(find.byKey(_logMeal)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Log Meal. Not available yet.',
        ),
      );

      expect(
        find.byKey(const ValueKey('quick-add-unavailable-note')),
        findsOne,
      );

      handle.dispose();
    });

    testWidgets('tapping Log Meal claims nothing and creates nothing',
        (tester) async {
      final controller = await _pump(tester);
      await _openQuickAdd(tester);

      await tester.enterText(
        find.byKey(const ValueKey('quick-add-calories')),
        '420',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(_logMeal), warnIfMissed: false);
      await tester.pumpAndSettle();

      // Still on the editor, no success surface of any kind, nothing logged.
      expect(find.byKey(_editor), findsOne);
      expect(find.byType(SnackBar), findsNothing);
      expect(controller.selectedDate, _today);
    });

    testWidgets('backing out of the editor leaves no trace', (tester) async {
      final controller = await _pump(tester);

      controller.select(_yesterday);
      await tester.pumpAndSettle();
      await _openQuickAdd(tester);

      await tester.enterText(
        find.byKey(const ValueKey('quick-add-meal-name')),
        'Dal and two roti',
      );
      await tester.enterText(
        find.byKey(const ValueKey('quick-add-calories')),
        '620',
      );
      await tester.pumpAndSettle();

      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byKey(_editor), findsNothing);
      expect(controller.selectedDate, _yesterday);
      expect(find.byKey(_emptyDayNote), findsOne);
      expect(find.text('Dal and two roti'), findsNothing);
      expect(find.text('620'), findsNothing);

      // Reopening starts empty: there is no draft behind this screen.
      await _openQuickAdd(tester);
      expect(_fieldText(tester, const ValueKey('quick-add-meal-name')), '');
      expect(_fieldText(tester, const ValueKey('quick-add-calories')), '');
    });
  });

  group('shell chrome', () {
    /// The production shape: `MealDiaryPage` inside a branch navigator, with
    /// the shell's own Today action outside it. A sheet on the branch
    /// navigator would leave that action live, so a reader could move the
    /// diary to today while an editor sat on top holding a historical date.
    Future<int Function()> pumpInShell(WidgetTester tester) async {
      var todayTaps = 0;
      final controller = MealDiaryDateController(clock: () => _now);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            mealDiaryDateControllerProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            builder: (context, child) => TioTheme(
              config: const TioThemeConfig(mode: TioThemeMode.light),
              child: child ?? const SizedBox.shrink(),
            ),
            home: Scaffold(
              appBar: AppBar(
                actions: [
                  IconButton(
                    key: const ValueKey('shell-today-action'),
                    onPressed: () => todayTaps++,
                    icon: const Icon(Icons.today),
                  ),
                ],
              ),
              body: Navigator(
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => const MealDiaryPage(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      return () => todayTaps;
    }

    testWidgets('Add Food covers the shell, not just the diary body',
        (tester) async {
      final todayTaps = await pumpInShell(tester);

      await _openAddFood(tester);
      expect(find.byKey(_sheet), findsOne);

      await tester.tap(
        find.byKey(const ValueKey('shell-today-action')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(todayTaps(), 0, reason: 'the shell action must be unreachable');
    });

    testWidgets('Quick Add covers the shell too', (tester) async {
      final todayTaps = await pumpInShell(tester);

      await _openQuickAdd(tester);
      expect(find.byKey(_editor), findsOne);

      await tester.tap(
        find.byKey(const ValueKey('shell-today-action')),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      expect(todayTaps(), 0, reason: 'the shell action must be unreachable');
    });
  });

  group('small phone', () {
    testWidgets('the whole flow fits a 320-wide phone without overflowing',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester);

      expect(find.byKey(_addAction), findsOne);
      final action = tester.getRect(find.byKey(_addAction));
      expect(action.right, lessThanOrEqualTo(320));
      expect(action.bottom, lessThanOrEqualTo(640));

      await _openAddFood(tester);
      expect(tester.takeException(), isNull);
      expect(find.byKey(_quickAddRow), findsOne);

      await tester.tap(find.byKey(_quickAddRow));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // The two macro fields sharing a row still fit side by side.
      final protein = tester.getRect(find.byKey(const ValueKey('quick-add-protein')));
      final carbs = tester.getRect(find.byKey(const ValueKey('quick-add-carbs')));
      expect(protein.right, lessThanOrEqualTo(carbs.left));
      expect(carbs.right, lessThanOrEqualTo(320));

      // The commit region is on screen rather than below the fold.
      expect(tester.getRect(find.byKey(_logMeal)).bottom, lessThanOrEqualTo(640));
    });

    testWidgets('scrolling to the end never parks content under the action',
        (tester) async {
      // Short enough that the compact diary body genuinely scrolls while the
      // action is still on screen.
      tester.view.physicalSize = const Size(360, 280);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester);
      expect(find.byKey(_addAction), findsOne);

      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // At the maximum extent the last of the body still clears the button's
      // footprint rather than sitting underneath it.
      expect(
        tester.getRect(find.byKey(_emptyDayNote)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byKey(_addAction)).top),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('the keyboard does not bury the commit region', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester);
      await _openQuickAdd(tester);

      final beforeKeyboard = tester.getRect(find.byKey(_logMeal));
      expect(beforeKeyboard.bottom, lessThanOrEqualTo(640));

      // A raised keyboard: the editor sheet pads itself by the view insets, so
      // the pinned actions ride above it instead of disappearing under it.
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      final withKeyboard = tester.getRect(find.byKey(_logMeal));
      expect(tester.takeException(), isNull);
      expect(withKeyboard.bottom, lessThanOrEqualTo(640 - 300));
      expect(find.byKey(_logMeal), findsOne);
    });
  });
}

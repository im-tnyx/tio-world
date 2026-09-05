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
const _searchCard = ValueKey('add-food-search');
const _photoCard = ValueKey('add-food-photo');
const _aiSurface = ValueKey('add-food-ai-text');
const _editor = ValueKey('quick-add-editor');
const _logMeal = ValueKey('meal-log-footer-primary');
const _footerCategory = ValueKey('meal-log-footer-category');
const _footerDateTime = ValueKey('meal-log-footer-date-time');
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

/// The error line the row renders beneath itself.
///
/// Deliberately read from the visible `Text` rather than from an `errorText`
/// property: the row follows the repository's existing numeric-editor
/// convention, where the message is its own widget and the field carries none.
String? _fieldError(WidgetTester tester, ValueKey<String> field) {
  final line = find.byKey(ValueKey('${field.value}-error'));
  if (line.evaluate().isEmpty) return null;
  return tester.widget<Text>(line).data;
}

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
          ValueKey('add-food-photo'),
          'Take a Photo. Not available yet.',
        ),
        (
          ValueKey('add-food-search'),
          'Search Food. Not available yet.',
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

    testWidgets('describing a meal is offered but cannot be typed into',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _openAddFood(tester);

      const surface = ValueKey('add-food-ai-text');
      const mic = ValueKey('add-food-voice');

      expect(find.byKey(surface), findsOne);
      expect(find.text('What did you eat?'), findsOne);

      // The keyboard glyph leads the surface, saying what kind of thing it is.
      // It is decorative: one icon, and no semantics node of its own, so a
      // screen reader hears the surface once rather than twice.
      final keyboard = find.byIcon(Icons.keyboard_alt_outlined);
      expect(keyboard, findsOne);
      expect(
        tester.getRect(keyboard).left,
        lessThan(tester.getRect(find.text('What did you eat?')).left),
        reason: 'the glyph leads the prompt',
      );
      expect(
        find.ancestor(of: keyboard, matching: find.byType(ExcludeSemantics)),
        findsWidgets,
        reason: 'the glyph must not reach the semantics tree on its own',
      );

      // It looks like somewhere to type and is not one: no field, no keyboard,
      // and nothing for assistive technology to edit or invoke.
      expect(
        find.descendant(
          of: find.byKey(_sheet),
          matching: find.byType(EditableText),
        ),
        findsNothing,
        reason: 'a live field here would collect a sentence and drop it',
      );
      expect(
        tester.getSemantics(find.byKey(surface)),
        matchesSemantics(
          hasEnabledState: true,
          isEnabled: false,
          label: 'What did you eat? Describe your meal. Not available yet.',
        ),
      );

      // The microphone is present, because the reader should see that voice is
      // coming, and separately disabled so it cannot pretend to listen.
      expect(find.byIcon(Icons.mic_none_rounded), findsOne);
      expect(
        tester.getSemantics(find.byKey(mic)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Voice input. Not available yet.',
        ),
      );

      await tester.tap(find.byKey(surface), warnIfMissed: false);
      await tester.tap(find.byKey(mic), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(_sheet), findsOne);
      expect(find.byKey(_editor), findsNothing);

      handle.dispose();
    });

    // The sheet used to render all four paths as one vertical list of equal
    // Settings rows, which is the layout TNYX-62 explicitly does not want.
    // These assertions are about geometry rather than presence, so flattening
    // it again fails here instead of at the next device review.
    for (final width in const [320.0, 400.0]) {
      testWidgets('the N5 hierarchy holds at ${width.toInt()}px wide',
          (tester) async {
        tester.view.physicalSize = Size(width, 720);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await _pump(tester);
        await _openAddFood(tester);
        expect(tester.takeException(), isNull, reason: 'no overflow');

        final describe = tester.getRect(find.byKey(_aiSurface));
        final photo = tester.getRect(find.byKey(_photoCard));
        final quickAdd = tester.getRect(find.byKey(_quickAddRow));
        final search = tester.getRect(find.byKey(_searchCard));

        // Top to bottom: describe it, photograph it, then the manual pair.
        expect(describe.bottom, lessThanOrEqualTo(photo.top));
        expect(photo.bottom, lessThanOrEqualTo(quickAdd.top));

        // Quick Add and Search share one row rather than stacking.
        expect(quickAdd.right, lessThanOrEqualTo(search.left));
        expect(quickAdd.top, moreOrLessEquals(search.top, epsilon: 1));
        expect(quickAdd.bottom, moreOrLessEquals(search.bottom, epsilon: 1));

        // The photo card spans the row the pair shares, so it reads as the
        // more prominent of the two levels.
        expect(photo.width, greaterThan(quickAdd.width));
        expect(photo.width, greaterThan(search.width));
        expect(photo.left, moreOrLessEquals(quickAdd.left, epsilon: 1));
        expect(photo.right, moreOrLessEquals(search.right, epsilon: 1));

        // And nothing runs off the side of a narrow phone.
        for (final rect in [describe, photo, quickAdd, search]) {
          expect(rect.left, greaterThanOrEqualTo(0));
          expect(rect.right, lessThanOrEqualTo(width));
        }

        // Quick Add is still the one that works, at either width.
        await tester.tap(find.byKey(_quickAddRow));
        await tester.pumpAndSettle();
        expect(find.byKey(_editor), findsOne);
      });
    }

    testWidgets('the header clears a status bar or cutout on a short viewport',
        (tester) async {
      // Short enough that the sheet has to reach the top of the screen, which
      // is the only situation where the top inset matters at all.
      tester.view.physicalSize = const Size(360, 320);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(top: 100);
      addTearDown(tester.view.reset);

      await _pump(tester);
      await _openAddFood(tester);
      expect(tester.takeException(), isNull);

      // The route removes the top padding unless the sheet opts back into it,
      // so without that opt-in the title and close button sit under the
      // status bar rather than below it.
      expect(
        tester.getRect(find.text('Add Food')).top,
        greaterThanOrEqualTo(100),
        reason: 'the title must clear the top system inset',
      );
      expect(
        tester.getRect(find.byKey(_sheetClose)).top,
        greaterThanOrEqualTo(100),
        reason: 'the close action must stay reachable below the inset',
      );

      // Still dismissible from there, and still only the sheet.
      await tester.tap(find.byKey(_sheetClose));
      await tester.pumpAndSettle();
      expect(find.byKey(_sheet), findsNothing);
      expect(find.byType(TioDateCalendar), findsOne);
    });

    testWidgets('the close action dismisses only the sheet', (tester) async {
      final controller = await _pump(tester);
      await _openAddFood(tester);

      await tester.tap(find.byKey(_sheetClose));
      await tester.pumpAndSettle();

      expect(find.byKey(_sheet), findsNothing);
      expect(find.byKey(_editor), findsNothing);
      expect(find.byType(TioDateCalendar), findsOne);
      expect(controller.selectedDate, _today);
    });
  });

  group('Quick Add manual nutrition editor', () {
    testWidgets('it opens on the day the diary is showing', (tester) async {
      final controller = await _pump(tester);

      controller.select(_yesterday);
      await tester.pumpAndSettle();
      await _openQuickAdd(tester);

      // The footer's date control carries it, and shows the day the reader
      // picked rather than today.
      expect(find.textContaining('Aug 19'), findsOne);
      expect(find.textContaining('Aug 20'), findsNothing);
      expect(controller.selectedDate, _yesterday);
    });

    testWidgets('it renders the bounded field set', (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      for (final key in const [
        ValueKey('quick-add-meal-name'),
        ValueKey('quick-add-calories'),
        ValueKey('quick-add-carbs'),
        ValueKey('quick-add-protein'),
        ValueKey('quick-add-fat'),
      ]) {
        expect(find.byKey(key), findsOne, reason: '$key should be rendered');
      }

      // Four numbers, in the owner-approved order, each labelled with its unit.
      for (final label in const [
        'Calories (kcal)',
        'Carbs (g)',
        'Protein (g)',
        'Fat (g)',
      ]) {
        expect(find.text(label), findsOne);
      }
      expect(
        tester.getRect(find.text('Calories (kcal)')).top,
        lessThan(tester.getRect(find.text('Carbs (g)')).top),
      );
      expect(
        tester.getRect(find.text('Carbs (g)')).top,
        lessThan(tester.getRect(find.text('Protein (g)')).top),
      );
      expect(
        tester.getRect(find.text('Protein (g)')).top,
        lessThan(tester.getRect(find.text('Fat (g)')).top),
      );

      // Fiber and micronutrients are deferred from this shell, not hidden
      // behind an expander.
      expect(find.byKey(const ValueKey('quick-add-fiber')), findsNothing);
      expect(find.textContaining('Fiber'), findsNothing);
      expect(find.textContaining('Micronutrient'), findsNothing);
    });

    testWidgets('the meal name is optional and gets the room to be read',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      const name = ValueKey('quick-add-meal-name');
      expect(find.text('Meal name (optional)'), findsOne);

      // Optional means blank is a fine resting state — no error, no block.
      expect(_fieldText(tester, name), isEmpty);
      expect(_fieldError(tester, name), isNull);

      // Larger than a number row: it is the field a reader identifies the meal
      // by later, so it is not squeezed to the same height as a value box.
      final nameHeight = tester.getRect(find.byKey(name)).height;
      final valueHeight =
          tester.getRect(find.byKey(const ValueKey('quick-add-calories')))
              .height;
      expect(nameHeight, greaterThan(valueHeight));

      await _type(tester, name, 'Dal and two roti');
      expect(_fieldText(tester, name), 'Dal and two roti');
    });

    testWidgets('a negative value is rejected in words', (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      const calories = ValueKey('quick-add-calories');
      await _type(tester, calories, '-5');

      expect(_fieldText(tester, calories), '-5');
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

      expect(_fieldText(tester, protein), '1.2.3');
      expect(_fieldError(tester, protein), 'Enter a number.');
      expect(find.text('Enter a number.'), findsOne);
    });

    testWidgets('a supported decimal is accepted as typed', (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      const fat = ValueKey('quick-add-fat');
      await _type(tester, fat, '1.5');

      expect(_fieldText(tester, fat), '1.5');
      expect(_fieldError(tester, fat), isNull);
    });

    // The point of these two is not that the values are unsupported — it is
    // that being unsupported must never quietly turn into a different number.
    testWidgets('a comma decimal is refused, never turned into 15',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      const calories = ValueKey('quick-add-calories');
      await _type(tester, calories, '1,5');

      expect(
        _fieldText(tester, calories),
        '1,5',
        reason: 'the reader must still see what they typed',
      );
      expect(
        _fieldText(tester, calories),
        isNot('15'),
        reason: 'stripping the comma would log ten times the meal',
      );
      expect(_fieldError(tester, calories), 'Enter a number.');
      expect(find.text('Enter a number.'), findsOne);
    });

    testWidgets('an alphanumeric value is refused, never trimmed to a number',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      const fat = ValueKey('quick-add-fat');
      await _type(tester, fat, '1e400abc');

      expect(_fieldText(tester, fat), '1e400abc');
      expect(_fieldText(tester, fat), isNot('1400'));
      expect(_fieldError(tester, fat), 'Enter a number.');
    });

    testWidgets('an overflowing exponent is refused rather than stored as '
        'infinity', (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      // `double.tryParse` succeeds here and returns infinity, so parseability
      // alone is not enough of a check.
      const carbs = ValueKey('quick-add-carbs');
      await _type(tester, carbs, '1e400');

      expect(_fieldText(tester, carbs), '1e400');
      expect(_fieldError(tester, carbs), 'Enter a number.');
    });

    testWidgets('a blank optional field is absent, not an error and not zero',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      for (final key in const [
        ValueKey('quick-add-carbs'),
        ValueKey('quick-add-protein'),
        ValueKey('quick-add-fat'),
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

      expect(find.byKey(const ValueKey('meal-log-footer-note')), findsOne);
      expect(find.text('Saving is not available yet.'), findsOne);

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

  group('Meal Log action footer', () {
    testWidgets('both controls sit above Log Meal, side by side',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);

      final category = tester.getRect(find.byKey(_footerCategory));
      final dateTime = tester.getRect(find.byKey(_footerDateTime));
      final logMeal = tester.getRect(find.byKey(_logMeal));

      // One divider, and only one: it marks where the scrolling body ends and
      // the pinned region begins. The rows above it are not separated.
      const divider = ValueKey('meal-log-footer-divider');
      expect(find.byKey(divider), findsOne);
      expect(
        find.descendant(of: find.byKey(_editor), matching: find.byType(Divider)),
        findsOne,
      );
      final line = tester.getRect(find.byKey(divider));
      expect(line.bottom, lessThanOrEqualTo(category.top));

      // Edge to edge: the sheet's own horizontal padding must not shorten it.
      final windowWidth = tester.view.physicalSize.width /
          tester.view.devicePixelRatio;
      expect(line.left, moreOrLessEquals(0, epsilon: 0.5));
      expect(line.right, moreOrLessEquals(windowWidth, epsilon: 0.5));
      expect(line.width, greaterThan(logMeal.width));

      // Flush against the body: the sheet leaves a gap above its actions, and
      // the line sits at the top of it rather than below it, so nothing reads
      // as dead space between the last field and the boundary.
      final body = tester.getRect(
        find
            .descendant(
              of: find.byKey(_editor),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
      );
      expect(line.top, lessThanOrEqualTo(body.bottom + 0.5));

      // Meal type on the left, date and time on the right, sharing a row.
      expect(category.right, lessThanOrEqualTo(dateTime.left));
      expect(category.top, moreOrLessEquals(dateTime.top, epsilon: 1));
      expect(category.bottom, moreOrLessEquals(dateTime.bottom, epsilon: 1));

      // Both above the commit, which spans the whole footer.
      expect(category.bottom, lessThanOrEqualTo(logMeal.top));
      expect(dateTime.bottom, lessThanOrEqualTo(logMeal.top));
      expect(logMeal.width, greaterThan(category.width));
      expect(logMeal.width, greaterThan(dateTime.width));
      expect(logMeal.left, lessThanOrEqualTo(category.left + 1));
      expect(logMeal.right, greaterThanOrEqualTo(dateTime.right - 1));
    });

    testWidgets('the category control names no real category and is disabled',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _openQuickAdd(tester);

      expect(find.text('Meal type'), findsOne);
      expect(
        tester.getSemantics(find.byKey(_footerCategory)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Meal type. Not available yet.',
        ),
      );

      // TNYX-67 owns category identity. Naming one here would be this screen
      // inventing a second, weaker version of it.
      for (final name in const ['Breakfast', 'Lunch', 'Dinner', 'Snacks']) {
        expect(find.text(name), findsNothing, reason: 'TNYX-67 owns $name');
      }

      await tester.tap(find.byKey(_footerCategory), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(_editor), findsOne);

      handle.dispose();
    });

    testWidgets('the date control shows the diary date and no invented time',
        (tester) async {
      final handle = tester.ensureSemantics();
      final controller = await _pump(tester);

      controller.select(_yesterday);
      await tester.pumpAndSettle();
      await _openQuickAdd(tester);

      // The designed calendar glyph leads the date, not a Material icon.
      expect(
        find.descendant(
          of: find.byKey(_footerDateTime),
          matching: find.byType(SvgPicture),
        ),
        findsOne,
      );
      expect(
        tester.getSemantics(find.byKey(_footerDateTime)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Date and time. Aug 19, time not set. Not available yet.',
        ),
      );

      // No picker, and no fabricated clock time: TNYX-114 owns that contract.
      await tester.tap(find.byKey(_footerDateTime), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(find.byType(TimePickerDialog), findsNothing);
      expect(controller.selectedDate, _yesterday);

      handle.dispose();
    });

    testWidgets('the footer stays put while the body scrolls', (tester) async {
      tester.view.physicalSize = const Size(320, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester);
      await _openQuickAdd(tester);
      expect(tester.takeException(), isNull);

      final before = tester.getRect(find.byKey(_logMeal));
      final body = find.descendant(
        of: find.byKey(_editor),
        matching: find.byType(SingleChildScrollView),
      );
      await tester.drag(body.first, const Offset(0, -200));
      await tester.pumpAndSettle();

      // The commit region did not move with the content, and never overlaps it.
      expect(tester.getRect(find.byKey(_logMeal)), before);
      expect(
        tester.getRect(find.byKey(const ValueKey('quick-add-fat'))).bottom,
        lessThanOrEqualTo(tester.getRect(find.byKey(_footerCategory)).top),
      );
      expect(before.bottom, lessThanOrEqualTo(560));
    });

    testWidgets('a raised keyboard does not bury the footer', (tester) async {
      tester.view.physicalSize = const Size(320, 560);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await _pump(tester);
      await _openQuickAdd(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 260);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final key in const [_footerCategory, _footerDateTime, _logMeal]) {
        expect(
          tester.getRect(find.byKey(key)).bottom,
          lessThanOrEqualTo(560 - 260),
          reason: '$key must ride above the keyboard',
        );
      }
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

      // Each nutrition value is its own full-width row, label left and a
      // compact number right, and nothing runs off the side.
      for (final key in const [
        ValueKey('quick-add-calories'),
        ValueKey('quick-add-carbs'),
        ValueKey('quick-add-protein'),
        ValueKey('quick-add-fat'),
      ]) {
        final field = tester.getRect(find.byKey(key));
        expect(field.right, lessThanOrEqualTo(320));
        expect(field.left, greaterThan(0));
      }
      final carbs = tester.getRect(find.byKey(const ValueKey('quick-add-carbs')));
      final protein =
          tester.getRect(find.byKey(const ValueKey('quick-add-protein')));
      expect(carbs.bottom, lessThanOrEqualTo(protein.top));

      // The commit region is on screen rather than below the fold.
      expect(tester.getRect(find.byKey(_logMeal)).bottom, lessThanOrEqualTo(640));
      expect(tester.getRect(find.byKey(_logMeal)).right, lessThanOrEqualTo(320));
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

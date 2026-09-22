import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';
import 'package:tio_shared/shared.dart';

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
const _aiTextField = ValueKey('add-food-ai-text-field');
const _aiKeyboard = ValueKey('add-food-keyboard');
const _aiSubmit = ValueKey('add-food-submit');
const _editor = ValueKey('quick-add-editor');
const _logMeal = ValueKey('meal-log-footer-primary');
const _footerCategory = ValueKey('meal-log-footer-category');
const _footerDateTime = ValueKey('meal-log-footer-date-time');
const _dateTimePicker = ValueKey('tio-date-time-wheel-picker');
const _dateTimePickerPopup = ValueKey('tio-date-time-picker-popup');
const _emptyDayNote = ValueKey('meal-diary-empty-day-note');

/// Changes the running app's theme mode without remounting anything.
///
/// Set by [_pump]. The point is to exercise a theme change while a modal is
/// already open, which is the case a fresh pump cannot reach.
late void Function(TioThemeMode mode) _setThemeMode;

Future<MealDiaryDateController> _pump(
  WidgetTester tester, {
  int? resolvedFirstDayOfWeek,
  TioThemeMode mode = TioThemeMode.light,
  Brightness? platformBrightness,
  DateTime Function()? quickAddClock,
  DateTime Function()? textMealClock,
  MealTextParseRepository? mealTextParseRepository,
  MealCategoriesRepository? mealCategoriesRepository,
  MealLogRepository? mealLogRepository,
}) async {
  final controller = MealDiaryDateController(clock: () => _now);

  if (platformBrightness != null) {
    tester.platformDispatcher.platformBrightnessTestValue = platformBrightness;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
  }

  var activeMode = mode;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mealDiaryDateControllerProvider.overrideWith((ref) => controller),
        if (mealLogRepository != null)
          mealDiaryMealLogRepositoryProvider.overrideWithValue(
            mealLogRepository,
          ),
      ],
      child: MaterialApp(
        // `builder` wraps the router/navigator itself, which is what puts
        // every route — including a root-navigator modal — inside TioTheme.
        // The StatefulBuilder only exists so a test can swap the mode in
        // place; production composition has no equivalent and needs none.
        builder: (context, child) => StatefulBuilder(
          builder: (context, setState) {
            _setThemeMode = (next) => setState(() => activeMode = next);
            return TioTheme(
              config: TioThemeConfig(mode: activeMode),
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
        home: Scaffold(
          body: MealDiaryPage(
            resolvedFirstDayOfWeek: resolvedFirstDayOfWeek,
            quickAddClock: quickAddClock ?? () => _now,
            textMealClock: textMealClock ?? () => _now,
            mealTextParseRepository: mealTextParseRepository,
            mealCategoriesRepository: mealCategoriesRepository,
          ),
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

Future<void> _type(
    WidgetTester tester, ValueKey<String> field, String text) async {
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
    testWidgets(
        'the bottom system inset stays inside the governed sheet surface',
        (tester) async {
      // A gesture bar / 3-button nav area below the sheet: SafeArea insets
      // the content above it, so TioSheet's own painted Material stops short
      // of the true screen bottom. That gap must be covered by the same
      // governed surface color, not left to expose the transparent route
      // background behind it.
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);

      await _pump(tester);
      await _openAddFood(tester);

      final expectedSurface =
          tester.element(find.byKey(_sheet)).tioColors.surface;
      final fillFinder = find.byKey(
        const ValueKey('meal-diary-add-food-bottom-inset-fill'),
      );
      expect(fillFinder, findsOneWidget);
      expect(
        tester.widget<ColoredBox>(fillFinder).color,
        expectedSurface,
        reason: 'the fill must be the same governed role TioSheet paints, '
            'not a hardcoded or mismatched color',
      );
      // The fill must be a sibling of the sheet, never an ancestor — an
      // ancestor wrapping TioSheet's own rounded-top Material would paint a
      // flat rectangle behind/around that rounded arc and square the corners.
      expect(
        find.ancestor(of: find.byKey(_sheet), matching: fillFinder),
        findsNothing,
        reason: 'the fill must not wrap the sheet or its rounded corners '
            'would be squared against it',
      );

      final fillRect = tester.getRect(fillFinder);
      final sheetRect = tester.getRect(find.byKey(_sheet));
      expect(
        fillRect.bottom,
        800,
        reason: 'the fill must reach the true bottom of the screen',
      );
      expect(
        sheetRect.bottom,
        lessThanOrEqualTo(fillRect.top),
        reason: "TioSheet's own Material stops above the inset — proving "
            'the gap this regression covers actually exists — and the fill '
            'starts exactly where it stops, without overlapping it',
      );

      // TioSheet's own rounded-top Material keeps its radius: nothing paints
      // an opaque rectangle behind it that would square those corners off.
      final sheetMaterial = tester.widget<Material>(
        find.descendant(of: find.byKey(_sheet), matching: find.byType(Material))
            .first,
      );
      expect(
        sheetMaterial.borderRadius,
        isNotNull,
        reason: "the sheet's rounded top corners must remain intact",
      );
    });

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

    testWidgets('describe meal fails closed when no parser is supplied',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _openAddFood(tester);

      expect(find.byKey(_aiSurface), findsOne);
      final field = tester.widget<TextField>(find.byKey(_aiTextField));
      expect(field.enabled, isFalse);
      expect(field.decoration?.hintText, 'What did you eat?');
      // The state line is the only place that says why the field is inert.
      expect(
        find.descendant(
          of: find.byKey(_aiSurface),
          matching: find.text('Not available yet'),
        ),
        findsOne,
      );
      expect(find.byKey(_aiSubmit), findsNothing);
      expect(find.byKey(const ValueKey('add-food-voice')), findsOne);

      expect(
        tester.getSemantics(find.byKey(_aiKeyboard)),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Show or hide keyboard',
        ),
      );
      expect(
        tester.getSemantics(find.byKey(const ValueKey('add-food-voice'))),
        matchesSemantics(
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
          label: 'Voice input. Not available yet.',
        ),
      );

      await tester.tap(find.byKey(_aiTextField), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byKey(_sheet), findsOne);

      handle.dispose();
    });

    testWidgets('blank keeps Mic and nonblank swaps only the right action to Send',
        (tester) async {
      final parser = _RecordingTextParseRepository();
      await _pump(tester, mealTextParseRepository: parser);
      await _openAddFood(tester);

      expect(find.byKey(const ValueKey('add-food-voice')), findsOne);
      expect(find.byKey(_aiSubmit), findsNothing);

      await tester.enterText(find.byKey(_aiTextField), '  plain yogurt  ');
      await tester.pump();

      expect(find.byKey(const ValueKey('add-food-voice')), findsNothing);
      expect(find.byKey(_aiSubmit), findsOne);

      await tester.enterText(find.byKey(_aiTextField), '   ');
      await tester.pump();

      expect(find.byKey(const ValueKey('add-food-voice')), findsOne);
      expect(find.byKey(_aiSubmit), findsNothing);
      expect(parser.inputs, isEmpty);
    });

    testWidgets(
        'describe meal shows a single prompt and no themed outline on the field',
        (tester) async {
      final parser = _RecordingTextParseRepository();
      await _pump(tester, mealTextParseRepository: parser);
      await _openAddFood(tester);

      // At rest the hint is the only prompt; there is no second caption.
      expect(find.text('What did you eat?'), findsOne);
      expect(find.text('Describe your meal'), findsNothing);
      expect(
        find.byKey(const ValueKey('add-food-ai-supporting-text')),
        findsNothing,
      );

      // The card owns the outline. TextField merges the active theme's
      // InputDecorationTheme before building the decorator, so this is the
      // decoration that is actually drawn, focused or not.
      final decoration = tester
          .widget<InputDecorator>(
            find.descendant(
              of: find.byKey(_aiTextField),
              matching: find.byType(InputDecorator),
            ),
          )
          .decoration;
      for (final border in <InputBorder?>[
        decoration.border,
        decoration.enabledBorder,
        decoration.focusedBorder,
        decoration.disabledBorder,
        decoration.errorBorder,
        decoration.focusedErrorBorder,
      ]) {
        expect(border, InputBorder.none);
      }
      expect(decoration.filled, isFalse);

      // A longer description wraps up to four lines before it scrolls.
      final field = tester.widget<TextField>(find.byKey(_aiTextField));
      expect(field.maxLines, 4);

      // The keyboard icon paints no splash or highlight around itself.
      final keyboard =
          tester.widget<InkResponse>(find.byKey(const ValueKey('add-food-keyboard')));
      expect(keyboard.splashFactory, NoSplash.splashFactory);
      for (final state in [
        <WidgetState>{},
        {WidgetState.pressed},
        {WidgetState.hovered},
        {WidgetState.focused},
      ]) {
        expect(keyboard.overlayColor!.resolve(state), TioPalette.transparent);
      }

      // The mic is the voice-logging entry point, so it keeps the primary
      // colour even while it is inert.
      final mic = tester.widget<Icon>(
        find.descendant(
          of: find.byKey(const ValueKey('add-food-voice')),
          matching: find.byType(Icon),
        ),
      );
      expect(mic.color, tester.element(find.byKey(_aiSurface)).tioColors.primary);

      // The prompt is drawn as a hint: muted and lighter than the text the
      // reader types, at the same size so nothing shifts once they start.
      final hint = field.decoration!.hintStyle!;
      expect(hint.color, isNot(field.style!.color));
      expect(hint.fontWeight, FontWeight.w400);
      expect(field.style!.fontWeight, FontWeight.w600);
      expect(hint.fontSize, field.style!.fontSize);
    });

    // The sheet must not rise with the keyboard or sink when it opens; its
    // bottom and everything from the Photo card down stay put. Only when the
    // keyboard would otherwise cover the describe card does the top part — the
    // title row and the describe card, keeping their spacing — move up
    // together, with the sheet's surface stretching upward to hold them.
    //
    // [navBar] is the 3-button navigation bar. While the keyboard is open it
    // covers that bar, so Android reports the bar as `padding` only until the
    // keyboard appears (`viewPadding` never changes). A sheet that followed
    // `padding` would sink by the bar's height the moment the keyboard opened.
    //
    // [mustMove] pins the cases where the outcome is not a matter of a few
    // pixels: `false` for a keyboard that cannot reach the card, `true` for one
    // that certainly covers it. `null` leaves it to the invariant below.
    void keyboardTest(
      String name,
      Size size,
      double keyboard, {
      double navBar = 0,
      bool? mustMove,
    }) {
      testWidgets('describe meal stays reachable with the keyboard on $name',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.view.padding = FakeViewPadding(bottom: navBar);
        tester.view.viewPadding = FakeViewPadding(bottom: navBar);
        addTearDown(tester.view.reset);
        final parser = _RecordingTextParseRepository();
        await _pump(tester, mealTextParseRepository: parser);
        await _openAddFood(tester);

        // The whole outlined card, not just the text inside it, has to end up
        // clear of the keyboard.
        final describeCard = find
            .ancestor(of: find.byKey(_aiTextField), matching: find.byType(TioCard))
            .first;
        final title = find.text('Add Food');
        final sheetBefore = tester.getRect(find.byKey(_sheet));
        final photoBefore = tester.getRect(find.byKey(_photoCard));
        final cardBefore = tester.getRect(describeCard);
        final titleBefore = tester.getRect(title);

        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        tester.view.padding = FakeViewPadding.zero;
        await tester.tap(find.byKey(_aiTextField));
        await tester.pumpAndSettle();

        final sheet = tester.getRect(find.byKey(_sheet));
        final card = tester.getRect(describeCard);
        final titleNow = tester.getRect(title);
        final keyboardTop = size.height - keyboard;

        // The bottom of the sheet and everything from the Photo card down do
        // not move.
        expect(sheet.bottom, sheetBefore.bottom);
        expect(tester.getRect(find.byKey(_photoCard)), photoBefore);

        // The title row and the card keep the same distance, whatever moves.
        expect(
          card.top - titleNow.bottom,
          moreOrLessEquals(cardBefore.top - titleBefore.bottom, epsilon: 0.5),
        );

        final alreadyClear = cardBefore.bottom + TioSpacing.sm <= keyboardTop;
        if (mustMove != null) expect(alreadyClear, !mustMove);

        if (alreadyClear) {
          // Nothing needs to make room, so nothing moves.
          expect(card, cardBefore);
          expect(titleNow, titleBefore);
          expect(sheet, sheetBefore);
        } else {
          // Exactly as much room as is missing, and no more.
          expect(
            card.bottom,
            moreOrLessEquals(keyboardTop - TioSpacing.sm, epsilon: 1),
            reason: 'the describe card must rest just above the keyboard',
          );
          final lift = cardBefore.top - card.top;
          expect(lift, greaterThan(0));
          // The title moves by the same amount and the surface stretches
          // upward by it.
          expect(titleBefore.top - titleNow.top, moreOrLessEquals(lift));
          expect(sheetBefore.top - sheet.top, moreOrLessEquals(lift));
        }
      });
    }

    keyboardTest('a 360x800 phone with a short keyboard', const Size(360, 800),
        200,
        mustMove: false);
    keyboardTest('a 360x800 phone', const Size(360, 800), 320);
    keyboardTest(
      'a 360x800 phone with 3-button navigation',
      const Size(360, 800),
      340,
      navBar: 48,
    );
    keyboardTest('a 360x800 phone with a very tall keyboard',
        const Size(360, 800), 460,
        mustMove: true);
    keyboardTest('a small 320x560 phone', const Size(320, 560), 260);

    // The tests above settle before they look, so they cannot tell a sheet that
    // clears the keyboard on the frame the keyboard arrives from one that does
    // so a frame later. The next two pump a single frame at a time.
    Finder describeCardOf() => find
        .ancestor(of: find.byKey(_aiTextField), matching: find.byType(TioCard))
        .first;

    testWidgets(
        'describe meal clears a keyboard that arrives in a single frame',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, mealTextParseRepository: _RecordingTextParseRepository());
      await _openAddFood(tester);

      final title = find.text('Add Food');
      final photoBefore = tester.getRect(find.byKey(_photoCard));
      final cardBefore = tester.getRect(describeCardOf());
      final titleBefore = tester.getRect(title);
      // Only a keyboard this tall reaches the card, so the very first frame it
      // appears in has to move something.
      expect(cardBefore.bottom, greaterThan(800 - 320 - TioSpacing.sm));

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pump();

      final card = tester.getRect(describeCardOf());
      expect(
        card.bottom,
        moreOrLessEquals(800 - 320 - TioSpacing.sm, epsilon: 1),
        reason: 'the card must already be clear on the first frame',
      );
      expect(tester.getRect(find.byKey(_photoCard)), photoBefore);
      expect(
        card.top - tester.getRect(title).bottom,
        moreOrLessEquals(cardBefore.top - titleBefore.bottom, epsilon: 0.5),
      );
    });

    testWidgets('describe meal follows a rising keyboard frame by frame',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await _pump(tester, mealTextParseRepository: _RecordingTextParseRepository());
      await _openAddFood(tester);

      final photoBefore = tester.getRect(find.byKey(_photoCard));
      final restBottom = tester.getRect(describeCardOf()).bottom;

      for (final keyboard in <double>[40, 120, 200, 280, 320]) {
        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        await tester.pump();

        // Never covered, and never lifted further than it has to be.
        final clear = 800 - keyboard - TioSpacing.sm;
        expect(
          tester.getRect(describeCardOf()).bottom,
          moreOrLessEquals(restBottom < clear ? restBottom : clear, epsilon: 1),
          reason: 'keyboard at $keyboard',
        );
        expect(tester.getRect(find.byKey(_photoCard)), photoBefore);
      }
    });

    testWidgets('describe meal re-measures when the text size changes',
        (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 1;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await _pump(tester, mealTextParseRepository: _RecordingTextParseRepository());
      await _openAddFood(tester);

      // Larger text makes everything below the gap taller.
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      await tester.pumpAndSettle();
      final restBottom = tester.getRect(describeCardOf()).bottom;
      final photoBefore = tester.getRect(find.byKey(_photoCard));

      tester.view.viewInsets = const FakeViewPadding(bottom: 320);
      await tester.pump();

      const clear = 800 - 320 - TioSpacing.sm;
      expect(
        tester.getRect(describeCardOf()).bottom,
        moreOrLessEquals(restBottom < clear ? restBottom : clear, epsilon: 1),
      );
      expect(tester.getRect(find.byKey(_photoCard)), photoBefore);
    });

    // Long enough to wrap onto four lines at any width used here.
    final fourLines = List.filled(40, 'chicken rice').join(' ');

    // A viewport too short for the sheet makes it scroll. It then already
    // fills all the height there is, so nothing can stretch upward; instead the
    // sheet is scrolled just far enough for the card to clear the keyboard,
    // and back again when the keyboard closes. The title row may scroll out of
    // view there. The outer scroll view is looked up from the sheet itself, not
    // by type, because the text field has a scrollable of its own.
    void scrollingSheetTest(
      String name,
      Size size,
      double keyboard, {
      required bool scrollsAtRest,
      double textScale = 1,
    }) {
      testWidgets('describe meal stays reachable in a short viewport: $name',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = textScale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await _pump(tester, mealTextParseRepository: _RecordingTextParseRepository());
        await _openAddFood(tester);

        // Looked up again each time: the scrollable replaces its position
        // object when the window metrics change.
        ScrollPosition scroll() =>
            Scrollable.of(tester.element(find.byKey(_sheet))).position;
        expect(scroll().maxScrollExtent > 0, scrollsAtRest);
        final cardBefore = tester.getRect(describeCardOf());
        final keyboardTop = size.height - keyboard;
        // Without any lift the keyboard would cover the card.
        expect(cardBefore.bottom, greaterThan(keyboardTop - TioSpacing.sm));

        tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
        await tester.pumpAndSettle();

        final card = tester.getRect(describeCardOf());
        // The sheet did not rise with the keyboard: what scrolls still reaches
        // the bottom of the screen, and it is the content that has moved.
        expect(scroll().viewportDimension, size.height);
        expect(scroll().pixels, greaterThan(0));
        // The card rests just above the keyboard, and the field inside it is on
        // screen above the keyboard. With very large text the card can be taller
        // than the room left above the keyboard, so its own top edge may scroll
        // off; the field is what has to stay reachable.
        expect(
          card.bottom,
          moreOrLessEquals(keyboardTop - TioSpacing.sm, epsilon: 1),
        );
        final field = tester.getRect(find.byKey(_aiTextField));
        expect(field.top, greaterThanOrEqualTo(0));
        expect(field.bottom, lessThanOrEqualTo(keyboardTop));
        // The Quick Add / Search row is still one row, inside the sheet.
        expect(
          tester.getRect(find.byKey(_quickAddRow)).top,
          tester.getRect(find.byKey(_searchCard)).top,
        );

        // Lines added while typing grow the card, and it still rests just above
        // the keyboard with the line being typed on screen.
        await tester.enterText(find.byKey(_aiTextField), fourLines);
        await tester.pumpAndSettle();
        final grown = tester.getRect(describeCardOf());
        expect(grown.height, greaterThan(card.height));
        expect(
          grown.bottom,
          moreOrLessEquals(keyboardTop - TioSpacing.sm, epsilon: 1),
        );
        expect(
          tester.getRect(find.byKey(_aiTextField)).bottom,
          lessThanOrEqualTo(keyboardTop),
        );
        await tester.enterText(find.byKey(_aiTextField), '');
        await tester.pumpAndSettle();

        // Closing the keyboard puts everything back where it was.
        tester.view.viewInsets = FakeViewPadding.zero;
        await tester.pumpAndSettle();
        expect(tester.getRect(describeCardOf()), cardBefore);
        expect(scroll().pixels, 0);
      });
    }

    scrollingSheetTest('an 800x300 landscape phone', const Size(800, 300), 200,
        scrollsAtRest: true);
    scrollingSheetTest(
        'an 800x360 landscape phone with a tall keyboard', const Size(800, 360),
        240,
        scrollsAtRest: false);
    scrollingSheetTest('an 800x360 landscape phone with large text',
        const Size(800, 360), 240,
        scrollsAtRest: true, textScale: 1.6);

    testWidgets('keyboard affordance focuses and hides without submitting',
        (tester) async {
      final parser = _RecordingTextParseRepository();
      await _pump(tester, mealTextParseRepository: parser);
      await _openAddFood(tester);

      final textField = tester.widget<TextField>(find.byKey(_aiTextField));
      expect(textField.focusNode!.hasFocus, isFalse);

      await tester.tap(find.byKey(_aiKeyboard));
      await tester.pump();
      expect(textField.focusNode!.hasFocus, isTrue);
      expect(parser.inputs, isEmpty);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.reset);
      await tester.pump();

      await tester.tap(find.byKey(_aiKeyboard));
      await tester.pump();
      expect(textField.focusNode!.hasFocus, isFalse);
      expect(parser.inputs, isEmpty);
    });

    testWidgets('recoverable parse failure keeps text and retries the same meal',
        (tester) async {
      var attempts = 0;
      final parser = _RecordingTextParseRepository(
        onParse: (_) async {
          attempts += 1;
          if (attempts == 1) {
            throw const MealTextParseFailure(
              MealTextParseFailureReason.incomplete,
            );
          }
          return _parsedDraft();
        },
      );
      final categories = InMemoryMealCategoriesRepository();
      final logs = InMemoryMealLogRepository(
        mealCategoriesRepository: categories,
        clock: () => _now,
      );

      await _pump(
        tester,
        mealTextParseRepository: parser,
        mealCategoriesRepository: categories,
        mealLogRepository: logs,
      );
      await _openAddFood(tester);
      await tester.enterText(find.byKey(_aiTextField), '  plain yogurt  ');
      await tester.pump();
      await tester.tap(find.byKey(_aiSubmit));
      await tester.pumpAndSettle();

      expect(find.byKey(_sheet), findsOne);
      expect(
        tester.widget<TextField>(find.byKey(_aiTextField)).controller!.text,
        '  plain yogurt  ',
      );
      expect(
        find.text(MealTextParseController.incompleteMessage),
        findsOne,
      );

      await tester.tap(find.byKey(_aiSubmit));
      await tester.pumpAndSettle();

      expect(parser.inputs, ['plain yogurt', 'plain yogurt']);
      expect(find.byKey(const ValueKey('meal-editor-create-page')), findsOne);
    });

    testWidgets(
        'parsed draft preserves selected diary date and logs only after editor confirmation',
        (tester) async {
      final parser = _RecordingTextParseRepository();
      final categories = InMemoryMealCategoriesRepository();
      final logs = InMemoryMealLogRepository(
        mealCategoriesRepository: categories,
        clock: () => _now,
      );
      final dates = await _pump(
        tester,
        mealTextParseRepository: parser,
        mealCategoriesRepository: categories,
        mealLogRepository: logs,
        textMealClock: () => _now,
      );

      dates.select(_yesterday);
      await tester.pumpAndSettle();
      await _openAddFood(tester);
      await tester.enterText(find.byKey(_aiTextField), '  plain yogurt  ');
      await tester.pump();
      expect(find.byKey(_aiSubmit), findsOne);
      await tester.testTextInput.receiveAction(TextInputAction.send);
      await tester.pumpAndSettle();

      expect(parser.inputs, ['plain yogurt']);
      expect(find.byKey(const ValueKey('meal-editor-create-page')), findsOne);
      expect(find.text('Breakfast'), findsOne);
      expect(find.text('Aug 19, 10:30'), findsOne);

      await tester.tap(find.byKey(_logMeal));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('meal-editor-create-page')), findsNothing);
      expect(dates.selectedDate, _yesterday);
      expect(find.text('Plain yogurt'), findsWidgets);
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
    testWidgets('it snapshots current local time, not the historical diary day',
        (tester) async {
      final controller = await _pump(tester);

      controller.select(_yesterday);
      await tester.pumpAndSettle();
      await _openQuickAdd(tester);

      expect(find.text('Aug 20, 10:30'), findsOne);
      expect(find.textContaining('Aug 19'), findsNothing);
      expect(controller.selectedDate, _yesterday);
    });

    testWidgets('a new draft snapshots once and does not tick untouched',
        (tester) async {
      var now = DateTime(2026, 9, 6, 0, 7, 45);
      var clockReads = 0;
      await _pump(
        tester,
        quickAddClock: () {
          clockReads++;
          return now;
        },
      );
      await _openQuickAdd(tester);

      expect(find.text('Sep 6, 00:07'), findsOne);
      expect(clockReads, 1);

      now = DateTime(2026, 9, 6, 0, 17, 10);
      await tester.pump(const Duration(minutes: 10));
      expect(find.text('Sep 6, 00:07'), findsOne);
      expect(clockReads, 1,
          reason: 'an untouched draft must not poll the clock');
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
      final valueHeight = tester
          .getRect(find.byKey(const ValueKey('quick-add-calories')))
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

    testWidgets(
        'an overflowing exponent is refused rather than stored as '
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

      expect(find.byKey(const ValueKey('meal-log-footer-note')), findsNothing);
      expect(find.text('Saving is not available yet.'), findsNothing);

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
      var now = _now;
      final controller = await _pump(tester, quickAddClock: () => now);

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

      // Reopening starts empty and snapshots again: there is no retained draft
      // behind this screen.
      now = DateTime(2026, 8, 20, 10, 45);
      await _openQuickAdd(tester);
      expect(_fieldText(tester, const ValueKey('quick-add-meal-name')), '');
      expect(_fieldText(tester, const ValueKey('quick-add-calories')), '');
      expect(find.text('Aug 20, 10:45'), findsOne);
    });
  });

  testWidgets('the editor header clears a top inset on a short viewport',
      (tester) async {
    // Short enough that the editor has to reach the top — the only situation
    // where the inset matters — but tall enough to still walk the flow.
    tester.view.physicalSize = const Size(360, 460);
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 100);
    addTearDown(tester.view.reset);

    await _pump(tester);
    await _openAddFood(tester);
    // The Add Food sheet is taller than this viewport, so its Quick Add card
    // starts below the fold. Scrolling to it is how a reader would reach it.
    await tester.ensureVisible(find.byKey(_quickAddRow));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_quickAddRow));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(_editor), findsOne);

    // The route strips the top padding unless the sheet opts back in, so
    // without that the handle and title sit under the status bar.
    expect(
      tester
          .getRect(
            find.descendant(
              of: find.byKey(_editor),
              matching: find.text('Quick Add'),
            ),
          )
          .top,
      greaterThanOrEqualTo(100),
      reason: 'the editor title must clear the top system inset',
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('tio-editor-sheet-handle'))).top,
      greaterThanOrEqualTo(100),
    );
  });

  testWidgets('an invalid value marks its own field, not just the page',
      (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);
    await _openQuickAdd(tester);

    const calories = ValueKey('quick-add-calories');

    // Valid to start with: nothing is claiming an error anywhere.
    expect(
      tester.getSemantics(find.byKey(calories)).validationResult,
      isNot(SemanticsValidationResult.invalid),
    );

    await _type(tester, calories, '-5');

    // The field itself reports invalid, so a screen reader sitting in it
    // hears that rather than nothing.
    expect(
      tester.getSemantics(find.byKey(calories)).validationResult,
      SemanticsValidationResult.invalid,
      reason: 'the error must be attached to the field it is about',
    );
    // And the message announces itself when it appears.
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('quick-add-calories-error')))
          .flagsCollection
          .isLiveRegion,
      isTrue,
    );

    // Other fields stay untouched by one field's error.
    expect(
      tester
          .getSemantics(find.byKey(const ValueKey('quick-add-fat')))
          .validationResult,
      isNot(SemanticsValidationResult.invalid),
    );

    await _type(tester, calories, '500');
    expect(
      tester.getSemantics(find.byKey(calories)).validationResult,
      isNot(SemanticsValidationResult.invalid),
    );

    handle.dispose();
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
        find.descendant(
            of: find.byKey(_editor), matching: find.byType(Divider)),
        findsOne,
      );
      final line = tester.getRect(find.byKey(divider));
      expect(line.bottom, lessThanOrEqualTo(category.top));

      // Edge to edge: the sheet's own horizontal padding must not shorten it.
      final windowWidth =
          tester.view.physicalSize.width / tester.view.devicePixelRatio;
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
      expect(
        category.center.dy,
        moreOrLessEquals(dateTime.center.dy, epsilon: 1),
        reason: 'the enabled 44dp date target and compact disabled category '
            'stay centered in one row',
      );
      expect(dateTime.height, TioWheelPickerTokens.compactSelectionHeight);

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

      // Corrected for the activated selector. This flow opens Quick Add with
      // no category source, and with none the control is honestly inert and
      // still names nothing — it invites a choice rather than guessing one.
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

    /* Legacy custom-wheel interaction coverage. The owner rejected that
     * presentation; popup/native-drum coverage below supersedes it.
    testWidgets('the date control is concrete and opens the picker inline',
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
          isEnabled: true,
          hasTapAction: true,
          label: 'Date and time. Aug 20, 10:30. Picker collapsed.',
        ),
      );

      expect(find.text('Today'), findsNothing);
      expect(find.byKey(_dateTimePicker), findsNothing);
      final barriersBefore = find.byType(ModalBarrier).evaluate().length;
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      expect(find.byKey(_dateTimePicker), findsOne);
      expect(find.byKey(_editor), findsOne);
      expect(find.byType(ModalBarrier), findsNWidgets(barriersBefore));
      expect(find.byType(CalendarDatePicker), findsNothing);
      expect(find.byType(TimePickerDialog), findsNothing);
      for (final label in const [
        'Select date and time',
        'When did you eat this?',
        'Done',
        'Save',
        'Apply',
      ]) {
        expect(find.text(label), findsNothing);
      }
      expect(controller.selectedDate, _yesterday);

      handle.dispose();
    });

    testWidgets('wheel changes update the footer and survive collapse/reopen',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('tio-date-time-wheel-date')),
        const Offset(0, TioWheelPickerTokens.itemExtent),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aug 20, 10:30'), findsOne,
          reason: 'the Date wheel cannot move later than local Today');

      await tester.drag(
        find.byKey(const ValueKey('tio-date-time-wheel-minute')),
        const Offset(0, -TioWheelPickerTokens.itemExtent),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aug 20, 10:30'), findsOne,
          reason: '10:31 is future and snaps to the real 10:30 boundary');

      await tester.drag(
        find.byKey(const ValueKey('tio-date-time-wheel-date')),
        const Offset(0, -TioWheelPickerTokens.itemExtent),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aug 19, 10:30'), findsOne);

      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();
      expect(find.byKey(_dateTimePicker), findsNothing);
      expect(find.text('Aug 19, 10:30'), findsOne);

      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();
      expect(find.byKey(_dateTimePicker), findsOne);
      expect(
        tester.widget<Text>(
          find.byKey(const ValueKey('tio-date-time-date-selected')),
        ).data,
        'Aug 19',
      );
    });

    testWidgets('future snap-back uses the fresh clock at each gesture',
        (tester) async {
      var now = DateTime(2026, 9, 6, 0, 7, 45);
      await _pump(tester, quickAddClock: () => now);
      await _openQuickAdd(tester);
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byKey(const ValueKey('tio-date-time-wheel-minute')),
        const Offset(0, -TioWheelPickerTokens.itemExtent),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sep 6, 00:07'), findsOne);
      expect(
        tester.widget<Text>(
          find.byKey(const ValueKey('tio-date-time-minute-selected')),
        ).data,
        '07',
      );

      now = DateTime(2026, 9, 6, 0, 17, 10);
      await tester.drag(
        find.byKey(const ValueKey('tio-date-time-wheel-hour')),
        const Offset(0, -TioWheelPickerTokens.itemExtent),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sep 6, 00:17'), findsOne);
      expect(
        tester.widget<Text>(
          find.byKey(const ValueKey('tio-date-time-minute-selected')),
        ).data,
        '17',
      );
      expect(
        tester.widget<Text>(
          find.byKey(const ValueKey('tio-date-time-hour-selected')),
        ).data,
        '12',
      );
      expect(
        tester.widget<Text>(
          find.byKey(const ValueKey('tio-date-time-period-selected')),
        ).data,
        'AM',
      );
    });

    testWidgets('midnight timer exposes new Today without pointer input',
        (tester) async {
      var now = DateTime(2026, 9, 5, 23, 59, 59);
      await _pump(tester, quickAddClock: () => now);
      await _openQuickAdd(tester);
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      now = DateTime(2026, 9, 6, 0, 0, 1);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('Today'), findsOneWidget);
      final dateWheel = tester.widget<ListWheelScrollView>(
        find.descendant(
          of: find.byKey(
            const ValueKey('tio-date-time-wheel-date'),
          ),
          matching: find.byType(ListWheelScrollView),
        ),
      );
      final dateController =
          dateWheel.controller! as FixedExtentScrollController;
      expect(dateController.selectedItem, 1,
          reason: 'the old draft is now one reachable detent before Today');
      expect(find.text('Sep 5, 23:59'), findsOneWidget);
    });

    testWidgets('form values survive picker interaction and collapse',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);
      await _type(tester, const ValueKey('quick-add-meal-name'), 'Dal and roti');
      await _type(tester, const ValueKey('quick-add-calories'), '420');

      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('tio-date-time-wheel-date')),
        const Offset(0, -TioWheelPickerTokens.itemExtent),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      expect(
        _fieldText(tester, const ValueKey('quick-add-meal-name')),
        'Dal and roti',
      );
      expect(
        _fieldText(tester, const ValueKey('quick-add-calories')),
        '420',
      );
      expect(find.text('Aug 19, 10:30'), findsOne);
    });

    });
    */

    testWidgets('the date control opens a floating native picker',
        (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);
      await _openQuickAdd(tester);
      final footerBefore = tester.getRect(find.byKey(_footerDateTime));
      final editorBefore = tester.getRect(find.byKey(_editor));

      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      expect(find.byKey(_dateTimePickerPopup), findsOne);
      expect(find.byKey(_dateTimePicker), findsOne);
      expect(find.byType(CupertinoDatePicker), findsOne);
      expect(tester.getRect(find.byKey(_footerDateTime)), footerBefore);
      expect(tester.getRect(find.byKey(_editor)), editorBefore);
      expect(find.text('Date'), findsNothing);
      expect(find.text('Hour'), findsNothing);
      expect(find.text('Minute'), findsNothing);
      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.mode, CupertinoDatePickerMode.dateAndTime);
      expect(picker.use24hFormat, isFalse);
      expect(picker.maximumDate, _now);

      handle.dispose();
    });

    testWidgets('the popup dismisses without discarding draft form values',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);
      await _type(
          tester, const ValueKey('quick-add-meal-name'), 'Dal and roti');
      await _type(tester, const ValueKey('quick-add-calories'), '420');
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(8, 300));
      await tester.pumpAndSettle();

      expect(find.byKey(_dateTimePickerPopup), findsNothing);
      expect(
        _fieldText(tester, const ValueKey('quick-add-meal-name')),
        'Dal and roti',
      );
      expect(_fieldText(tester, const ValueKey('quick-add-calories')), '420');
    });

    testWidgets('outside dismissal stops the maximum-date refresh timer',
        (tester) async {
      var now = DateTime(2026, 8, 20, 10, 30, 45);
      var clockReads = 0;
      DateTime clock() {
        clockReads++;
        return now;
      }

      await _pump(tester, quickAddClock: clock);
      await _openQuickAdd(tester);
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      final readsAfterOpen = clockReads;
      now = DateTime(2026, 8, 20, 10, 31, 5);
      await tester.pump(const Duration(seconds: 20));
      await tester.pumpAndSettle();
      expect(
        clockReads,
        greaterThan(readsAfterOpen),
        reason: 'an open picker refreshes at the next minute boundary',
      );

      await tester.tapAt(const Offset(8, 300));
      await tester.pumpAndSettle();
      expect(find.byKey(_dateTimePickerPopup), findsNothing);

      final readsAfterDismiss = clockReads;
      now = DateTime(2026, 8, 20, 10, 33, 5);
      await tester.pump(const Duration(minutes: 2));
      await tester.pumpAndSettle();
      expect(
        clockReads,
        readsAfterDismiss,
        reason: 'outside dismissal must cancel the recurring timer',
      );

      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();
      expect(
        clockReads,
        greaterThan(readsAfterDismiss),
        reason: 'reopening schedules fresh clock-bound refreshes',
      );
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

    /* Native Cupertino DateTime geometry has a wider minimum than a 320dp
     * test viewport. It is covered at an owner-usable width by the popup test.
    testWidgets('inline picker stays usable on a small keyboard viewport',
        (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 220);
      addTearDown(tester.view.reset);

      await _pump(tester);
      await _openQuickAdd(tester);
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byKey(_dateTimePicker), findsOne);
      expect(find.byKey(_logMeal), findsOne);

      final viewport = tester.getRect(
        find
            .descendant(
              of: find.byKey(_editor),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
      );
      final pickerCard = tester.getRect(find.byKey(_dateTimePickerCard));
      final footer = tester.getRect(find.byKey(_footerCategory));
      expect(pickerCard.top, lessThan(viewport.bottom));
      expect(pickerCard.bottom, greaterThan(viewport.top));
      final minuteWheel = find.byKey(
        const ValueKey('tio-date-time-wheel-minute'),
      );
      final minuteCenter = tester.getCenter(minuteWheel);
      expect(minuteCenter.dy, greaterThanOrEqualTo(viewport.top));
      expect(minuteCenter.dy, lessThanOrEqualTo(viewport.bottom));
      await tester.drag(
        minuteWheel,
        const Offset(0, TioWheelPickerTokens.itemExtent),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(viewport.bottom, lessThanOrEqualTo(footer.top + 0.5));
      expect(tester.getRect(find.byKey(_logMeal)).bottom, lessThanOrEqualTo(380));
    });
    */
  });

  group('modal theme inheritance', () {
    // Both flows are presented on the root navigator. `MaterialApp.builder`
    // wraps that navigator in `TioTheme`, so a root modal route is inside the
    // theme rather than beside it — but that is an architectural claim, and
    // these tests are what stop it from quietly becoming untrue.

    /// The painted material for a surface.
    ///
    /// Some keys sit on the Material itself and some on a wrapper, so both are
    /// accepted rather than making the caller know which.
    Material materialOf(WidgetTester tester, Finder scope) {
      final self = scope.evaluate();
      if (self.isNotEmpty && self.first.widget is Material) {
        return self.first.widget as Material;
      }
      return tester.widget<Material>(
        find.descendant(of: scope, matching: find.byType(Material)).first,
      );
    }

    BoxDecoration decorationOf(WidgetTester tester, Finder scope) => tester
        .widgetList<Container>(
          find.descendant(of: scope, matching: find.byType(Container)),
        )
        .map((container) => container.decoration)
        .whereType<BoxDecoration>()
        .first;

    Color? textColorOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text).first).style?.color;

    /// Representative Add Food surfaces, one per distinct semantic role.
    void expectAddFood(WidgetTester tester, TioColors expected, String mode) {
      expect(
        materialOf(tester, find.byKey(_sheet)).color,
        expected.surface,
        reason: '$mode: the sheet material must be the active surface',
      );
      expect(
        decorationOf(tester, find.byKey(_photoCard)).color,
        expected.surfaceRaised,
        reason: '$mode: a normal card must be the active raised surface',
      );
      expect(
        (decorationOf(
          tester,
          // The key sits on the text column inside the card, so the
          // outline belongs to the card around it.
          find
              .ancestor(
                of: find.byKey(_aiSurface),
                matching: find.byType(TioCard),
              )
              .first,
        ).border! as Border)
            .top
            .color,
        expected.outlineStrong,
        reason: '$mode: the outlined describe surface must use the outline',
      );
      expect(
        tester
            .widget<Icon>(
              find.descendant(
                of: find.byKey(_quickAddRow),
                matching: find.byIcon(Icons.add_rounded),
              ),
            )
            .color,
        expected.primary,
        reason: '$mode: the one enabled action keeps the primary colour',
      );
      expect(textColorOf(tester, 'Add Food'), expected.textPrimary);
      expect(textColorOf(tester, 'Quick Add'), expected.textPrimary);
    }

    /// Representative Quick Add surfaces, including the reusable footer.
    void expectQuickAdd(WidgetTester tester, TioColors expected, String mode) {
      expect(
        materialOf(tester, find.byKey(const ValueKey('tio-editor-sheet')))
            .color,
        expected.surfaceRaised,
        reason: '$mode: the editor sheet must be the active raised surface',
      );
      expect(
        tester
            .widget<Divider>(
              find.byKey(const ValueKey('meal-log-footer-divider')),
            )
            .color,
        expected.outlineStrong.withAlpha(TioAlpha.alpha20),
        reason: '$mode: the footer rule follows the active outline',
      );
      expect(textColorOf(tester, 'Meal type'), expected.textPrimary);
      expect(
        tester
            .widget<SvgPicture>(
              find.descendant(
                of: find.byKey(_footerDateTime),
                matching: find.byType(SvgPicture),
              ),
            )
            .colorFilter,
        ColorFilter.mode(expected.textPrimary, BlendMode.srcIn),
        reason: '$mode: the calendar glyph is tinted, not baked',
      );
      if (find.byKey(_dateTimePickerPopup).evaluate().isNotEmpty) {
        expect(
          decorationOf(tester, find.byKey(_dateTimePickerPopup)).color,
          expected.surface,
          reason: '$mode: the popup card follows the active surface role',
        );
        expect(
          tester
              .widgetList<CupertinoTheme>(find.byType(CupertinoTheme))
              .last
              .data
              .textTheme
              .dateTimePickerTextStyle
              .color,
          expected.textPrimary,
          reason: '$mode: the native wheel follows the active semantic palette',
        );
      }
    }

    testWidgets('Light resolves the Light palette', (tester) async {
      await _pump(tester);
      await _openAddFood(tester);
      expectAddFood(tester, TioColors.light, 'light');

      await tester.tap(find.byKey(_quickAddRow));
      await tester.pumpAndSettle();
      expectQuickAdd(tester, TioColors.light, 'light');
    });

    testWidgets('Tio Dark resolves navy through the real modal route',
        (tester) async {
      await _pump(tester, mode: TioThemeMode.tioDark);

      // Opened the way a reader opens it, so the root-navigator hop is part of
      // what is being tested rather than bypassed by building the sheet here.
      await _openAddFood(tester);
      expectAddFood(tester, TioColors.dark, 'tio dark');
      expect(
        materialOf(tester, find.byKey(_sheet)).color,
        isNot(TioColors.light.surface),
        reason: 'a root modal must not fall back to Light',
      );

      await tester.tap(find.byKey(_quickAddRow));
      await tester.pumpAndSettle();
      expectQuickAdd(tester, TioColors.dark, 'tio dark');
      expect(
        materialOf(tester, find.byKey(const ValueKey('tio-editor-sheet')))
            .color,
        isNot(TioColors.light.surfaceRaised),
      );
    });

    // TNYX-157: Dark is the standard pure-black palette (`TioColors.oled`).
    testWidgets('Dark resolves the pure-black palette', (tester) async {
      await _pump(tester, mode: TioThemeMode.dark);
      await _openAddFood(tester);
      expectAddFood(tester, TioColors.oled, 'dark');

      await tester.tap(find.byKey(_quickAddRow));
      await tester.pumpAndSettle();
      expectQuickAdd(tester, TioColors.oled, 'dark');
      expect(
        materialOf(tester, find.byKey(const ValueKey('tio-editor-sheet')))
            .color,
        isNot(TioColors.dark.surfaceRaised),
        reason: 'Dark (pure-black) is not an alias of Tio Dark',
      );
    });

    testWidgets('System with an OS-dark device resolves pure-black Dark',
        (tester) async {
      await _pump(
        tester,
        mode: TioThemeMode.system,
        platformBrightness: Brightness.dark,
      );

      await _openAddFood(tester);
      expectAddFood(tester, TioColors.oled, 'system+dark');

      await tester.tap(find.byKey(_quickAddRow));
      await tester.pumpAndSettle();
      expectQuickAdd(tester, TioColors.oled, 'system+dark');
    });

    testWidgets('an open Add Food sheet follows a live theme change',
        (tester) async {
      await _pump(tester);
      await _openAddFood(tester);
      expectAddFood(tester, TioColors.light, 'before');

      // The sheet is already on screen. Changing the config must reach it
      // where it stands, not only the next time it is opened.
      _setThemeMode(TioThemeMode.dark);
      await tester.pumpAndSettle();

      expect(find.byKey(_sheet), findsOne, reason: 'the sheet stays open');
      expectAddFood(tester, TioColors.oled, 'after');
    });

    testWidgets('an open Quick Add editor follows a live theme change',
        (tester) async {
      await _pump(tester);
      await _openQuickAdd(tester);
      expectQuickAdd(tester, TioColors.light, 'before');

      // Typed first, so the survival check below is not empty-to-empty: a
      // rebuild that recreated the editor and its controllers would clear
      // this, and an unwritten field would hide that.
      const calories = ValueKey('quick-add-calories');
      await _type(tester, calories, '420');
      expect(_fieldText(tester, calories), '420');
      await tester.tap(find.byKey(_footerDateTime));
      await tester.pumpAndSettle();
      expectQuickAdd(tester, TioColors.light, 'picker before');

      _setThemeMode(TioThemeMode.dark);
      await tester.pumpAndSettle();

      expect(find.byKey(_editor), findsOne, reason: 'the editor stays open');
      expectQuickAdd(tester, TioColors.oled, 'after');
      expect(find.byKey(_dateTimePicker), findsOne);
      expect(
        _fieldText(tester, calories),
        '420',
        reason: 'a theme change must not throw away what was typed',
      );
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

  group('reusable footer, enabled path', () {
    Future<void> pumpFooter(
      WidgetTester tester, {
      required VoidCallback? onCategory,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => TioTheme(
            config: const TioThemeConfig(mode: TioThemeMode.light),
            child: child ?? const SizedBox.shrink(),
          ),
          home: Scaffold(
            body: Center(
              child: MealLogActionFooter(
                mealCategoryLabel: 'Meal type',
                dateTimeLabel: 'Aug 20 · Time',
                primaryLabel: 'Log Meal',
                onMealCategoryTap: onCategory,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Quick Add passes null today, but the widget exposes an enabled path for
    // the Meal Editor to adopt, and that path has to be pressable when it is.
    testWidgets('an enabled control is a real target and reports its tap',
        (tester) async {
      var taps = 0;
      await pumpFooter(tester, onCategory: () => taps++);

      final control = tester.getRect(find.byKey(_footerCategory));
      expect(
        control.height,
        greaterThanOrEqualTo(44),
        reason: 'a pressable control needs a pressable amount of room',
      );
      expect(control.width, greaterThanOrEqualTo(48));
      expect(
        find.descendant(
          of: find.byKey(_footerCategory),
          matching: find.byType(InkWell),
        ),
        findsOne,
        reason:
            'an InkWell brings focus and a ripple; a detector brings neither',
      );

      await tester.tap(find.byKey(_footerCategory));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('a disabled control stays compact and unpressable',
        (tester) async {
      await pumpFooter(tester, onCategory: null);

      // No 48dp floor here: that rule is about things you can press.
      expect(
        find.descendant(
          of: find.byKey(_footerCategory),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
      expect(tester.getRect(find.byKey(_footerCategory)).height, lessThan(48));
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
      final carbs =
          tester.getRect(find.byKey(const ValueKey('quick-add-carbs')));
      final protein =
          tester.getRect(find.byKey(const ValueKey('quick-add-protein')));
      expect(carbs.bottom, lessThanOrEqualTo(protein.top));

      // The commit region is on screen rather than below the fold.
      expect(
          tester.getRect(find.byKey(_logMeal)).bottom, lessThanOrEqualTo(640));
      expect(
          tester.getRect(find.byKey(_logMeal)).right, lessThanOrEqualTo(320));
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

      await tester.drag(
          find.byType(SingleChildScrollView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // At the maximum extent the last of the body still clears the button's
      // footprint rather than sitting underneath it.
      expect(
        tester.getRect(find.byKey(_emptyDayNote)).bottom,
        lessThanOrEqualTo(tester.getRect(find.byKey(_addAction)).top),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('a bottom inset is reserved as well as the button itself',
        (tester) async {
      // No bottom navigation and a gesture bar: SafeArea lifts the action by
      // the inset, so the body has to reserve the inset too or the last line
      // ends up underneath it.
      tester.view.physicalSize = const Size(360, 300);
      tester.view.devicePixelRatio = 1;
      tester.view.padding = const FakeViewPadding(bottom: 48);
      addTearDown(tester.view.reset);

      await _pump(tester);
      expect(find.byKey(_addAction), findsOne);

      // Asserted as the invariant rather than by scrolling: today's body is
      // short enough never to reach the bottom, so a scroll test would pass
      // whether or not the reservation is right. What has to hold is that the
      // reserved band covers everything between the viewport floor and the
      // top of the button — inset included.
      final reserved = (tester
              .widget<SingleChildScrollView>(
                find.byType(SingleChildScrollView).first,
              )
              .padding! as EdgeInsets)
          .bottom;
      final action = tester.getRect(find.byKey(_addAction));

      expect(
        reserved,
        greaterThanOrEqualTo(300 - action.top),
        reason: 'the bottom inset lifts the button, so it must be reserved too',
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


final class _RecordingTextParseRepository implements MealTextParseRepository {
  _RecordingTextParseRepository({this.onParse});

  final Future<MealLoggingDraft> Function(String text)? onParse;
  final List<String> inputs = [];

  @override
  Future<MealLoggingDraft> parseMealText(String text) {
    inputs.add(text);
    return onParse?.call(text) ?? Future.value(_parsedDraft());
  }
}

MealLoggingDraft _parsedDraft() => MealLoggingDraft(
      mealName: 'Plain yogurt',
      captureSource: MealLogCaptureSource.text,
      items: [
        MealLoggingDraftItem(
          displayName: 'Plain yogurt',
          quantity: 200,
          servingUnit: 'g',
          consumedNutritionSnapshot: NutritionSnapshot(
            schemaVersion: 1,
            nutrients: const {
              NutrientId.energy: 120,
              NutrientId.protein: 7,
              NutrientId.carbohydrate: 9,
              NutrientId.fat: 6,
            },
          ),
        ),
      ],
    );

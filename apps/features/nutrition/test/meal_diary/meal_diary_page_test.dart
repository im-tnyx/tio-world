import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_nutrition/nutrition.dart';

/// A fixed clock so "today" is the same day in every run, which is the whole
/// point of the diary passing `localToday` in rather than the calendar reading
/// the system clock for itself.
final _now = DateTime(2026, 8, 20, 10, 30);
final _today = DateTime(2026, 8, 20);

Future<MealDiaryDateController> _pump(WidgetTester tester) async {
  // The provider owns disposal, so this test does not also tear it down.
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
        home: const Scaffold(body: MealDiaryPage()),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return controller;
}

TioDateCalendar _calendar(WidgetTester tester) =>
    tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));

Finder _cell(DateTime date) => find.byKey(ValueKey(date));

void main() {
  testWidgets('Meal Diary renders the reusable core calendar', (tester) async {
    await _pump(tester);

    expect(find.byType(TioDateCalendar), findsOne);
    expect(_cell(_today), findsOne);
  });

  testWidgets('the diary stops at today', (tester) async {
    final controller = await _pump(tester);

    final calendar = _calendar(tester);
    expect(calendar.maxDate, _today);
    expect(calendar.localToday, _today);
    expect(calendar.selectedDate, _today);
    expect(
      calendar.minDate,
      DateTime(2026, 8, 20 - MealDiaryDateController.historyWindowDays),
    );
    expect(controller.maxDate, controller.localToday);
  });

  testWidgets('a future date is unreachable', (tester) async {
    final controller = await _pump(tester);
    final tomorrow = DateTime(2026, 8, 21);

    // Tomorrow stays drawn so the week keeps its shape, but the diary will not
    // move to it however it is asked.
    expect(_cell(tomorrow), findsOne);

    await tester.tap(_cell(tomorrow));
    await tester.pumpAndSettle();
    expect(controller.selectedDate, _today);

    await tester.tap(find.byKey(const ValueKey('tio-date-calendar-handle')));
    await tester.pumpAndSettle();
    await tester.tap(_cell(tomorrow));
    await tester.pumpAndSettle();
    expect(controller.selectedDate, _today);

    // Even asked directly, the diary refuses tomorrow.
    controller.select(tomorrow);
    expect(controller.selectedDate, _today);
  });

  testWidgets('a past date updates the diary selection', (tester) async {
    final controller = await _pump(tester);
    final yesterday = DateTime(2026, 8, 19);

    await tester.tap(_cell(yesterday));
    await tester.pumpAndSettle();

    expect(controller.selectedDate, yesterday);
    expect(_calendar(tester).selectedDate, yesterday);
  });

  testWidgets('the date controller exposes and restores Today state',
      (tester) async {
    final controller = await _pump(tester);
    final yesterday = DateTime(2026, 8, 19);

    expect(controller.isOnToday, isTrue);

    controller.select(yesterday);
    await tester.pumpAndSettle();
    expect(controller.isOnToday, isFalse);

    controller.selectToday();
    await tester.pumpAndSettle();
    expect(controller.isOnToday, isTrue);
    expect(controller.selectedDate, _today);
  });

  testWidgets('Today action state also follows the visible calendar week',
      (tester) async {
    final controller = await _pump(tester);

    expect(controller.isOnToday, isTrue);
    expect(controller.isTodayVisible, isTrue);
    expect(controller.shouldShowTodayAction, isFalse);

    await tester.fling(
      find.byKey(const ValueKey('tio-date-calendar-week-pager')),
      const Offset(400, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(controller.isOnToday, isTrue);
    expect(controller.isTodayVisible, isFalse);
    expect(controller.shouldShowTodayAction, isTrue);

    controller.selectToday();
    await tester.pumpAndSettle();

    expect(controller.selectedDate, _today);
    expect(controller.isTodayVisible, isTrue);
    expect(controller.shouldShowTodayAction, isFalse);
    expect(_cell(_today), findsOne);
  });

  testWidgets('with no nutrition data the calendar still works and invents none',
      (tester) async {
    final controller = await _pump(tester);

    // No decorations at all rather than a fabricated zero: missing progress and
    // a real zero are different statements about the user's day.
    expect(_calendar(tester).decorationBuilder, isNull);

    final unselected = DateTime(2026, 8, 18);
    final circle = tester.renderObject(
      find.descendant(of: _cell(unselected), matching: find.byType(CustomPaint)),
    );
    expect(circle, isNot(paints..circle()));
    expect(circle, isNot(paints..arc()));

    // Navigation is unaffected by the absence of data.
    await tester.tap(_cell(unselected));
    await tester.pumpAndSettle();
    expect(controller.selectedDate, unselected);

    await tester.tap(find.byKey(const ValueKey('tio-date-calendar-handle')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('tio-date-calendar-month-pager')),
      findsOne,
    );
    expect(find.text('August 2026'), findsNothing);
  });

  testWidgets('Nutrition does not own a week-start preference', (tester) async {
    await _pump(tester);

    // First day of week is one app-wide value. Passing anything here would make
    // Nutrition a second owner of it.
    expect(_calendar(tester).resolvedFirstDayOfWeek, isNull);
  });
}

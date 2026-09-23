import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  DateTime call() => value;
}

Future<WorkoutDateController> _pump(
  WidgetTester tester, {
  int resolvedFirstDayOfWeek = DateTime.monday,
  _MutableClock? clock,
}) async {
  final resolvedClock = clock ?? _MutableClock(DateTime(2026, 9, 23, 14, 30));
  final dates = WorkoutDateController(clock: resolvedClock.call);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        workoutDateControllerProvider.overrideWith((ref) => dates),
      ],
      child: MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: WorkoutHomePage(
            resolvedFirstDayOfWeek: resolvedFirstDayOfWeek,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return dates;
}

void main() {
  testWidgets('starts on local today with no Workout decorations', (tester) async {
    final dates = await _pump(tester);

    final calendar =
        tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(calendar.localToday, DateTime(2026, 9, 23));
    expect(calendar.selectedDate, DateTime(2026, 9, 23));
    expect(calendar.resolvedFirstDayOfWeek, DateTime.monday);
    expect(calendar.decorationBuilder, isNull);
    expect(calendar.controller, same(dates.calendarController));
    expect(calendar.minDate, DateTime(2025, 9, 23));
    expect(calendar.maxDate, DateTime(2027, 9, 23));
  });

  testWidgets('owns selection and exposes the return-to-Today action',
      (tester) async {
    final dates = await _pump(tester);

    final calendar =
        tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    calendar.onDateSelected(DateTime(2026, 9, 24, 18));
    await tester.pump();

    final updated =
        tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(updated.selectedDate, DateTime(2026, 9, 24));
    expect(dates.shouldShowTodayAction, isTrue);

    dates.selectToday();
    await tester.pumpAndSettle();

    expect(dates.selectedDate, DateTime(2026, 9, 23));
    expect(dates.shouldShowTodayAction, isFalse);
  });

  testWidgets('forwards the app-global resolved week start', (tester) async {
    await _pump(tester, resolvedFirstDayOfWeek: DateTime.sunday);

    final calendar =
        tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(calendar.resolvedFirstDayOfWeek, DateTime.sunday);
  });

  testWidgets('tracks viewport month and offers Today while viewport is away',
      (tester) async {
    final dates = await _pump(tester);

    expect(dates.isOnToday, isTrue);
    expect(dates.isTodayVisible, isTrue);
    expect(dates.shouldShowTodayAction, isFalse);

    await tester.fling(
      find.byKey(const ValueKey('tio-date-calendar-week-pager')),
      const Offset(-400, 0),
      1200,
    );
    await tester.pumpAndSettle();

    expect(dates.isOnToday, isTrue);
    expect(dates.isTodayVisible, isFalse);
    expect(dates.shouldShowTodayAction, isTrue);

    dates.selectToday();
    await tester.pumpAndSettle();

    expect(dates.isOnToday, isTrue);
    expect(dates.isTodayVisible, isTrue);
    expect(
      dates.visibleMonth,
      DateTime(dates.localToday.year, dates.localToday.month),
    );
  });

  testWidgets('refreshes local Today after app resume without moving selection',
      (tester) async {
    final clock = _MutableClock(DateTime(2026, 9, 23, 23, 55));
    final dates = await _pump(tester, clock: clock);

    expect(dates.selectedDate, DateTime(2026, 9, 23));
    expect(dates.localToday, DateTime(2026, 9, 23));

    clock.value = DateTime(2026, 9, 24, 8);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(dates.localToday, DateTime(2026, 9, 24));
    expect(dates.selectedDate, DateTime(2026, 9, 23));
    expect(dates.shouldShowTodayAction, isTrue);
  });
}

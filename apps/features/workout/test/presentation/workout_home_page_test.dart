import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_workout/workout.dart';

Future<void> _pump(
  WidgetTester tester, {
  int resolvedFirstDayOfWeek = DateTime.monday,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => TioTheme(
        config: const TioThemeConfig(mode: TioThemeMode.light),
        child: child ?? const SizedBox.shrink(),
      ),
      home: Scaffold(
        body: WorkoutHomePage(
          resolvedFirstDayOfWeek: resolvedFirstDayOfWeek,
          clock: () => DateTime(2026, 9, 23, 14, 30),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('starts on local today with no Workout decorations', (tester) async {
    await _pump(tester);

    final calendar =
        tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(calendar.localToday, DateTime(2026, 9, 23));
    expect(calendar.selectedDate, DateTime(2026, 9, 23));
    expect(calendar.resolvedFirstDayOfWeek, DateTime.monday);
    expect(calendar.decorationBuilder, isNull);
    expect(calendar.minDate.isBefore(calendar.localToday), isTrue);
    expect(calendar.maxDate.isAfter(calendar.localToday), isTrue);
  });

  testWidgets('owns selected date when the shared calendar reports selection',
      (tester) async {
    await _pump(tester);

    final calendar =
        tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    calendar.onDateSelected(DateTime(2026, 9, 24, 18));
    await tester.pump();

    final updated =
        tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(updated.selectedDate, DateTime(2026, 9, 24));
  });

  testWidgets('forwards the app-global resolved week start', (tester) async {
    await _pump(tester, resolvedFirstDayOfWeek: DateTime.sunday);

    final calendar =
        tester.widget<TioDateCalendar>(find.byType(TioDateCalendar));
    expect(calendar.resolvedFirstDayOfWeek, DateTime.sunday);
  });
}

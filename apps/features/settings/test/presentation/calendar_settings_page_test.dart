import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_settings/settings.dart';

void main() {
  Future<void> pumpPage(
    WidgetTester tester, {
    FirstDayOfWeekPreference initial = FirstDayOfWeekPreference.monday,
    ValueChanged<FirstDayOfWeekPreference>? onChanged,
  }) async {
    var current = initial;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: StatefulBuilder(
          builder: (context, setState) {
            return CalendarSettingsPage(
              firstDayOfWeek: current,
              onFirstDayOfWeekChanged: (next) {
                current = next;
                setState(() {});
                onChanged?.call(next);
              },
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the two V1 choices with Monday selected by default',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await pumpPage(tester);

      expect(find.text('First day of week'), findsOneWidget);
      expect(find.text('Monday (default)'), findsOneWidget);
      expect(find.text('Sunday'), findsOneWidget);
      expect(find.textContaining('Automatic'), findsNothing);
      expect(find.textContaining('System default'), findsNothing);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Monday (default)')),
        isSemantics(isSelected: true, isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sunday')),
        isSemantics(isSelected: false, isButton: true, hasTapAction: true),
      );
    } finally {
      semantics.dispose();
    }
  });

  testWidgets('tapping Sunday then Monday updates selected state immediately',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      final changes = <FirstDayOfWeekPreference>[];
      await pumpPage(tester, onChanged: changes.add);

      await tester.tap(
        find.byKey(const ValueKey('calendar-first-day-option-sunday')),
      );
      await tester.pumpAndSettle();

      expect(changes, [FirstDayOfWeekPreference.sunday]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Sunday')),
        isSemantics(isSelected: true),
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel('Monday (default)')),
        isSemantics(isSelected: false),
      );

      await tester.tap(
        find.byKey(const ValueKey('calendar-first-day-option-monday')),
      );
      await tester.pumpAndSettle();

      expect(changes, [
        FirstDayOfWeekPreference.sunday,
        FirstDayOfWeekPreference.monday,
      ]);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Monday (default)')),
        isSemantics(isSelected: true),
      );
    } finally {
      semantics.dispose();
    }
  });
}

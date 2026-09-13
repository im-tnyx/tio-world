import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets(
    'progress is the outer ring and selection touches it from inside',
    (tester) async {
      final selected = DateTime(2026, 9, 13);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TioTheme(
              config: const TioThemeConfig(mode: TioThemeMode.light),
              child: TioDateCalendar(
                selectedDate: selected,
                localToday: selected,
                minDate: DateTime(2026, 9, 1),
                maxDate: selected,
                allowExpansion: false,
                onDateSelected: (_) {},
                decorationBuilder: (date) => date == selected
                    ? const TioDateDecoration(
                        progress: 0.5,
                        fill: TioDateFill.solid,
                      )
                    : null,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cell = find.byKey(ValueKey(selected));
      final circle = tester.renderObject(
        find.descendant(of: cell, matching: find.byType(CustomPaint)),
      );

      // Owner-approved +1 radius step: a normal-scale date cell is now 30dp,
      // giving outer radius 15. The 2dp progress stroke is centred at radius
      // 14, while the 0.5dp selection stroke is centred at radius 12.75. Their
      // edges still meet at radius 13, so the larger rings retain zero gap.
      expect(
        circle,
        paints
          ..circle(radius: 12.5)
          ..circle(radius: 14, strokeWidth: 2)
          ..arc()
          ..circle(radius: 12.75, strokeWidth: 0.5),
      );
    },
  );
}

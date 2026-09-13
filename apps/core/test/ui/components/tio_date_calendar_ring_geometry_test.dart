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

      // A normal-scale date cell is 28dp: outer radius 14. The 2dp progress
      // stroke is centred at radius 13, so its inner edge is radius 12. The
      // 0.5dp selection stroke is centred at radius 11.75, putting its outer
      // edge at the same radius 12. The rings therefore touch with no gap.
      expect(
        circle,
        paints
          ..circle(radius: 11.5)
          ..circle(radius: 13, strokeWidth: 2)
          ..arc()
          ..circle(radius: 11.75, strokeWidth: 0.5),
      );
    },
  );
}

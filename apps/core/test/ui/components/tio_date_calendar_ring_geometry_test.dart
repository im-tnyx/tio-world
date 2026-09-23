import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

/// The palette each explicit mode resolves to at runtime (`TioTheme`). Mode
/// names are product semantics: `dark` is the pure-black palette, while
/// `tioDark` is the navy/slate one.
TioColors _paletteFor(TioThemeMode mode, {required bool highContrast}) {
  final base = switch (mode) {
    TioThemeMode.light => TioColors.light,
    TioThemeMode.dark => TioColors.oled,
    TioThemeMode.tioDark => TioColors.dark,
    TioThemeMode.system => throw ArgumentError('system is not exercised here'),
  };
  return highContrast ? base.highContrast : base;
}

void main() {
  final selected = DateTime(2026, 9, 13);

  Future<RenderObject> pumpSelected(
    WidgetTester tester, {
    required TioThemeMode mode,
    required bool highContrast,
    required TioDateDecoration decoration,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TioTheme(
            config: TioThemeConfig(mode: mode, highContrast: highContrast),
            child: TioDateCalendar(
              selectedDate: selected,
              localToday: selected,
              minDate: DateTime(2026, 9, 1),
              maxDate: selected,
              allowExpansion: false,
              onDateSelected: (_) {},
              decorationBuilder: (date) => date == selected ? decoration : null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cell = find.byKey(ValueKey(selected));
    return tester.renderObject(
      find.descendant(of: cell, matching: find.byType(CustomPaint)),
    );
  }

  for (final mode in [
    TioThemeMode.light,
    TioThemeMode.dark,
    TioThemeMode.tioDark,
  ]) {
    for (final highContrast in [false, true]) {
      final variant = '${mode.name}${highContrast ? ' high contrast' : ''}';
      final expectedColors = _paletteFor(mode, highContrast: highContrast);

      testWidgets('the selected disk sits inside progress in $variant',
          (tester) async {
        expect(expectedColors.progress, isNot(expectedColors.primary));

        final circle = await pumpSelected(
          tester,
          mode: mode,
          highContrast: highContrast,
          decoration: const TioDateDecoration(progress: 0.5),
        );

        // A normal-scale date cell is 30dp, giving outer radius 15. The 2dp
        // progress stroke is centred at radius 14, so its inner edge is 13.
        // The tonal selection disk fills out to exactly 13: the footprint the
        // retired 0.5dp selection ring occupied, with no gap to progress.
        expect(
          circle,
          paints
            ..circle(
              radius: 13,
              style: PaintingStyle.fill,
              color: expectedColors.primary.withValues(
                alpha: TioOpacity.opacity12,
              ),
            )
            ..circle(radius: 14, strokeWidth: 2)
            ..arc(color: expectedColors.progress, strokeWidth: 2),
        );
        expect(circle, isNot(paints..circle(strokeWidth: 0.5)));
      });

      testWidgets(
        'a feature fill keeps the ring beside progress in $variant',
        (tester) async {
          final circle = await pumpSelected(
            tester,
            mode: mode,
            highContrast: highContrast,
            decoration: const TioDateDecoration(
              progress: 0.5,
              fill: TioDateFill.solid,
            ),
          );

          // The 0.5dp selection stroke is centred at radius 12.75 and meets
          // the progress ring's inner edge at 13, so the rings keep zero gap.
          // Selection/fill use primary; progress uses the distinct semantic
          // progress role so dark palettes do not render both rings white.
          expect(
            circle,
            paints
              ..circle(radius: 12.5, color: expectedColors.primary)
              ..circle(radius: 14, strokeWidth: 2)
              ..arc(color: expectedColors.progress, strokeWidth: 2)
              ..circle(
                radius: 12.75,
                strokeWidth: 0.5,
                color: expectedColors.primary,
              ),
          );
        },
      );
    }
  }
}

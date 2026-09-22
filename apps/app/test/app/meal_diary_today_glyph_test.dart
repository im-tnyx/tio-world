import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/meal_diary_today_glyph.dart';
import 'package:tio_core/core.dart';

/// Geometry contract for the Meal Diary "Today" glyph: the day number must sit
/// inside the drawn calendar body, not on its bottom stroke.
///
/// `ic_calendar.svg` draws the body from the header divider at y 9.5 to the
/// bottom stroke at y 21.5, so the body centre is y 15.5 in the 24dp box.
const _glyphBox = 24.0;
const _bodyTop = 9.5;
const _bodyBottom = 21.5;
const _bodyCentre = (_bodyTop + _bodyBottom) / 2;
const _bodyLeft = 3.0;
const _bodyRight = 21.0;

const _glyphKey = ValueKey('meal-diary-today-glyph');
const _labelKey = ValueKey('meal-diary-today-day-label');

void main() {
  Future<void> pumpGlyph(
    WidgetTester tester, {
    required int day,
    required TioThemeMode mode,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: TioThemeConfig(mode: mode),
          child: MediaQuery.withClampedTextScaling(
            minScaleFactor: textScale,
            maxScaleFactor: textScale,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
        home: Scaffold(
          body: Center(
            child: Builder(
              builder: (context) => MealDiaryTodayGlyph(
                localToday: DateTime(2026, 9, day),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final day in const [4, 12, 28]) {
    for (final textScale in const [1.0, 1.6]) {
      testWidgets(
          'day $day stays centred in the calendar body at ${textScale}x',
          (tester) async {
        await pumpGlyph(
          tester,
          day: day,
          mode: TioThemeMode.dark,
          textScale: textScale,
        );

        final glyph = tester.getRect(find.byKey(_glyphKey));
        final label = tester.getRect(find.byKey(_labelKey));

        expect(glyph.width, _glyphBox);
        expect(glyph.height, _glyphBox);
        // Horizontally centred in the icon.
        expect(label.center.dx, closeTo(glyph.center.dx, 0.5));
        // Vertically centred on the body, not the icon box.
        expect(
          label.center.dy - glyph.top,
          closeTo(_bodyCentre, 0.75),
          reason: 'the date must sit on the body centre (y $_bodyCentre)',
        );
        // Never touching the divider above or the stroke below.
        expect(label.top - glyph.top, greaterThanOrEqualTo(_bodyTop));
        expect(label.bottom - glyph.top, lessThanOrEqualTo(_bodyBottom));
        // Two digits stay inside the drawn body, never on a side stroke.
        // (The test font draws square glyphs, so "12" is far wider here than
        // with a real typeface — which is exactly the case worth pinning.)
        expect(label.left - glyph.left, greaterThanOrEqualTo(_bodyLeft));
        expect(label.right - glyph.left, lessThanOrEqualTo(_bodyRight));
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final testCase in const [
    (name: 'Light', mode: TioThemeMode.light, colors: TioColors.light),
    (name: 'Dark', mode: TioThemeMode.dark, colors: TioColors.oled),
    (name: 'Tio Dark', mode: TioThemeMode.tioDark, colors: TioColors.dark),
  ]) {
    testWidgets('${testCase.name} paints the date with the info accent',
        (tester) async {
      await pumpGlyph(tester, day: 12, mode: testCase.mode);

      final label = tester.widget<Text>(find.byKey(_labelKey));

      expect(label.style?.color, testCase.colors.info);
      expect(
        label.style?.color,
        isNot(testCase.colors.textPrimary),
        reason: 'the date is an accent, not the outline colour',
      );
    });
  }
}

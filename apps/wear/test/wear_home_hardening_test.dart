import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';
import 'package:tio_wear/src/device/wear_display_shape.dart';
import 'package:tio_wear/src/home/presentation/wear_home_screen.dart';
import 'package:tio_wear/wear_app.dart';

void main() {
  group('Wear App Mode eligibility', () {
    test('null mode preserves the existing mixed seven-tile menu', () {
      expect(
        WearHomeScreen.tilesForMode(null).map((tile) => tile.title),
        const [
          'Workout Routine',
          'Workout This Week',
          'Add Food',
          'Add Water',
          'View Summary',
          'Nutrition',
          'Settings',
        ],
      );
    });

    test('workout mode hides nutrition-only placeholders', () {
      expect(
        WearHomeScreen.tilesForMode(AppMode.workout).map((tile) => tile.title),
        const [
          'Workout Routine',
          'Workout This Week',
          'View Summary',
          'Settings',
        ],
      );
    });

    test('nutrition mode hides workout-only placeholders', () {
      expect(
        WearHomeScreen.tilesForMode(AppMode.nutrition).map((tile) => tile.title),
        const [
          'Add Food',
          'Add Water',
          'View Summary',
          'Nutrition',
          'Settings',
        ],
      );
    });

    test('hybrid mode keeps both current product lanes', () {
      expect(WearHomeScreen.tilesForMode(AppMode.hybrid), hasLength(7));
    });
  });

  group('Wear display shape', () {
    test('rectangular displays preserve the existing horizontal inset', () {
      expect(
        wearHorizontalSafeInset(
          shortestSide: 200,
          shape: WearDisplayShape.rectangular,
          baselineInset: TioSpacing.md,
        ),
        TioSpacing.md,
      );
    });

    test('round displays use the inscribed-square safe inset', () {
      final expected = 200 * (1 - 1 / math.sqrt(2)) / 2;

      expect(
        wearHorizontalSafeInset(
          shortestSide: 200,
          shape: WearDisplayShape.round,
          baselineInset: TioSpacing.md,
        ),
        closeTo(expected, 0.0001),
      );
    });

    testWidgets('round screen applies the computed inset to the action list',
        (tester) async {
      const size = Size(200, 200);
      final expected = wearHorizontalSafeInset(
        shortestSide: size.shortestSide,
        shape: WearDisplayShape.round,
        baselineInset: TioSpacing.md,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: size),
            child: WearHomeScreen(displayShape: WearDisplayShape.round),
          ),
        ),
      );

      final listView = tester.widget<ListView>(find.byType(ListView));
      final padding = listView.padding! as EdgeInsets;

      expect(padding.left, closeTo(expected, 0.0001));
      expect(padding.right, closeTo(expected, 0.0001));
    });
  });

  testWidgets('TioWearApp uses the canonical OLED Tio theme', (tester) async {
    await tester.pumpWidget(const TioWearApp());

    final context = tester.element(find.byType(WearHomeScreen));
    final theme = Theme.of(context);
    final colors = theme.extension<TioColors>();

    expect(theme.brightness, Brightness.dark);
    expect(colors, isNotNull);
    expect(colors!.background, TioPalette.black);
  });
}

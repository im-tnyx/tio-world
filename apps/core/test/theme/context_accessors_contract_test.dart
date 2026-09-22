import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  test('exactly four runtime theme modes exist', () {
    expect(TioThemeMode.values, [
      TioThemeMode.system,
      TioThemeMode.light,
      TioThemeMode.dark,
      TioThemeMode.tioDark,
    ]);
  });

  // Dark is the standard pure-black palette (`oled`), Tio Dark is the
  // navy/slate palette (`dark`), and System never resolves to Tio Dark.
  for (final testCase in [
    (
      name: 'Light',
      mode: TioThemeMode.light,
      platformBrightness: Brightness.dark,
      colors: TioColors.light,
      shadows: TioShadows.light,
    ),
    (
      name: 'Dark',
      mode: TioThemeMode.dark,
      platformBrightness: Brightness.light,
      colors: TioColors.oled,
      shadows: TioShadows.oled,
    ),
    (
      name: 'Tio Dark',
      mode: TioThemeMode.tioDark,
      platformBrightness: Brightness.light,
      colors: TioColors.dark,
      shadows: TioShadows.dark,
    ),
    (
      name: 'System on an OS-light device',
      mode: TioThemeMode.system,
      platformBrightness: Brightness.light,
      colors: TioColors.light,
      shadows: TioShadows.light,
    ),
    (
      name: 'System on an OS-dark device',
      mode: TioThemeMode.system,
      platformBrightness: Brightness.dark,
      colors: TioColors.oled,
      shadows: TioShadows.oled,
    ),
  ]) {
    testWidgets(
        '${testCase.name} context accessors resolve canonical runtime '
        'contracts', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue =
          testCase.platformBrightness;
      addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
      late TioColors colors;
      late TioShadows shadows;
      late TioMotionScheme motion;

      await tester.pumpWidget(
        MaterialApp(
          home: TioTheme(
            config: TioThemeConfig(mode: testCase.mode),
            child: Builder(
              builder: (context) {
                colors = context.tioColors;
                shadows = context.tioShadows;
                motion = context.tioMotion;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(colors.isDark, testCase.colors.isDark);
      expect(colors.background, testCase.colors.background);
      expect(colors.surface, testCase.colors.surface);
      expect(colors.surfaceRaised, testCase.colors.surfaceRaised);
      expect(colors.textPrimary, testCase.colors.textPrimary);
      expect(shadows.soft, testCase.shadows.soft);
      expect(
        shadows.elevatedPanelColor,
        testCase.shadows.elevatedPanelColor,
      );
      expect(motion.reducedMotion, isFalse);
      expect(motion.normal, const TioMotionScheme.standard().normal);
    });
  }

  testWidgets('Dark and Tio Dark resolve distinct palettes', (tester) async {
    Future<TioColors> resolve(TioThemeMode mode) async {
      late TioColors colors;
      await tester.pumpWidget(
        MaterialApp(
          home: TioTheme(
            config: TioThemeConfig(mode: mode),
            child: Builder(
              builder: (context) {
                colors = context.tioColors;
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      return colors;
    }

    final dark = await resolve(TioThemeMode.dark);
    final tioDark = await resolve(TioThemeMode.tioDark);

    expect(dark.background, TioPalette.black);
    expect(tioDark.background, TioPalette.neutral950);
    expect(dark.surface, isNot(tioDark.surface));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('preserves visible Material touch feedback', (tester) async {
    late ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) {
            theme = Theme.of(context);
            return const Scaffold(body: Text('Theme probe'));
          },
        ),
      ),
    );

    expect(theme.splashFactory, isNot(same(NoSplash.splashFactory)));
    expect(theme.splashColor, isNot(Colors.transparent));
  });

  testWidgets('high contrast changes light semantic foregrounds',
      (tester) async {
    late TioColors colors;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(
            mode: TioThemeMode.light,
            highContrast: true,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) {
            colors = context.tioColors;
            return const Scaffold(body: Text('Theme probe'));
          },
        ),
      ),
    );

    expect(colors.textPrimary, const Color(0xFF000000));
    expect(colors.textMuted, const Color(0xFF374151));
    expect(
        Theme.of(tester.element(find.text('Theme probe'))).colorScheme.outline,
        colors.outlineStrong);
  });

  testWidgets('high contrast changes dark semantic surfaces', (tester) async {
    late TioColors colors;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(
            mode: TioThemeMode.dark,
            highContrast: true,
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) {
            colors = context.tioColors;
            return const Scaffold(body: Text('Theme probe'));
          },
        ),
      ),
    );

    expect(colors.background, const Color(0xFF000000));
    expect(colors.textPrimary, const Color(0xFFFFFFFF));
    expect(colors.textMuted, const Color(0xFFD1D5DB));
  });

  testWidgets('reduced motion disables transitions and exposes zero durations',
      (tester) async {
    late bool disableAnimations;
    late TioMotionScheme motion;
    late PageTransitionsTheme transitions;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(reducedMotion: true),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) {
            disableAnimations = MediaQuery.of(context).disableAnimations;
            motion = context.tioMotion;
            transitions = Theme.of(context).pageTransitionsTheme;
            return const Scaffold(body: Text('Theme probe'));
          },
        ),
      ),
    );

    expect(disableAnimations, isTrue);
    expect(motion.reducedMotion, isTrue);
    expect(motion.fast, Duration.zero);
    expect(motion.normal, Duration.zero);
    expect(motion.slow, Duration.zero);
    expect(motion.fadeThroughEnter, Duration.zero);
    expect(motion.fadeThroughExit, Duration.zero);
    expect(motion.progress, Duration.zero);
    expect(transitions.builders, hasLength(TargetPlatform.values.length));
  });

  test('interactive outlines meet non-text contrast in every base theme', () {
    for (final colors in const [
      TioColors.light,
      TioColors.dark,
      TioColors.oled,
    ]) {
      expect(
        _contrastRatio(colors.outlineStrong, colors.surface),
        greaterThanOrEqualTo(3),
      );
    }
  });

  testWidgets('OLED mode exposes pure-black semantic background',
      (tester) async {
    late TioColors colors;
    late ThemeData theme;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.oled),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Builder(
          builder: (context) {
            colors = context.tioColors;
            theme = Theme.of(context);
            return const Scaffold(body: Text('OLED probe'));
          },
        ),
      ),
    );

    expect(colors.background, Colors.black);
    expect(colors.surface, const Color(0xFF050505));
    expect(colors.textPrimary, Colors.white);
    expect(theme.brightness, Brightness.dark);
    expect(theme.scaffoldBackgroundColor, Colors.black);
    expect(theme.navigationBarTheme.backgroundColor, colors.surface);
  });
}

double _contrastRatio(Color foreground, Color background) {
  final lighter = foreground.computeLuminance() > background.computeLuminance()
      ? foreground
      : background;
  final darker = identical(lighter, foreground) ? background : foreground;
  return (lighter.computeLuminance() + 0.05) /
      (darker.computeLuminance() + 0.05);
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  testWidgets('theme context accessors resolve canonical runtime contracts', (
    tester,
  ) async {
    late TioColors colors;
    late TioShadows shadows;
    late TioMotionScheme motion;
    late double radiusSmall;
    late double radiusMedium;
    late double radiusLarge;

    await tester.pumpWidget(
      MaterialApp(
        home: TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.dark),
          child: Builder(
            builder: (context) {
              colors = context.tioColors;
              shadows = context.tioShadows;
              motion = context.tioMotion;
              radiusSmall = context.radiusSmall;
              radiusMedium = context.radiusMedium;
              radiusLarge = context.radiusLarge;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(colors.background, TioColors.dark.background);
    expect(colors.surface, TioColors.dark.surface);
    expect(
      shadows.elevatedPanelColor,
      TioShadows.dark.elevatedPanelColor,
    );
    expect(motion.reducedMotion, isFalse);
    expect(motion.normal, const TioMotionScheme.standard().normal);

    // Compatibility getters remain available only while live feature
    // consumers migrate, but they must resolve through canonical radius roles.
    expect(radiusSmall, TioRadius.sm);
    expect(radiusMedium, TioRadius.md);
    expect(radiusLarge, TioRadius.lg);
  });
}

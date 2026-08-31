import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
// The wheels are not exported from the package barrel; the existing wheel
// regression test reaches them the same way.
import 'package:tio_feature_onboarding/src/presentation/widgets/wheels/onboarding_height_wheel.dart';

void main() {
  testWidgets('light theme selection pill uses a contrasting surface role',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => TioTheme(
          config: const TioThemeConfig(mode: TioThemeMode.light),
          child: child ?? const SizedBox.shrink(),
        ),
        home: Scaffold(
          body: OnboardingHeightWheel(
            valueCm: 170,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final pill = tester.widget<Container>(
      find.byKey(const ValueKey('onboarding-height-wheel-selection-pill')),
    );
    final decoration = pill.decoration! as BoxDecoration;

    expect(
      decoration.color,
      TioColors.light.surfaceVariant.withAlpha(
        TioWheelPickerTokens.selectionSurfaceAlpha,
      ),
    );

    // The defect this pins: in light theme these two roles are the same
    // colour, so painting the pill from `surface` over a `surfaceRaised`
    // host rendered it white-on-white.
    expect(TioColors.light.surface, TioColors.light.surfaceRaised);
    expect(
        TioColors.light.surfaceVariant, isNot(TioColors.light.surfaceRaised));
  });
}

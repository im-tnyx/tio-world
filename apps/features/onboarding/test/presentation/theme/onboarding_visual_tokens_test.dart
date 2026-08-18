import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/src/presentation/theme/onboarding_visual_tokens.dart';

void main() {
  group('Product Onboarding shell visual contracts', () {
    test('keeps top chrome and content geometry', () {
      expect(OnboardingVisualTokens.topBarHeight, 48.0);
      expect(OnboardingVisualTokens.progressThickness, 4.0);
      expect(OnboardingVisualTokens.contentBottomClearance, 100.0);
      expect(OnboardingVisualTokens.wheelSheetDividerAlpha, 45);
      expect(OnboardingVisualTokens.wheelSheetDividerWidth, 1.0);
    });

    test('keeps normal bottom-bar gradient treatment', () {
      expect(
        OnboardingVisualTokens.normalGradientStops,
        const <double>[0.0, 0.25, 0.70, 1.0],
      );
      expect(OnboardingVisualTokens.normalGradientTransparentOpacity, 0.0);
      expect(OnboardingVisualTokens.normalGradientMidOpacity, 0.50);
      expect(OnboardingVisualTokens.normalGradientStrongOpacity, 0.95);
      expect(OnboardingVisualTokens.normalGradientOpaqueOpacity, 1.0);
    });

    test('keeps contextual info-link presentation', () {
      expect(OnboardingVisualTokens.infoTopPadding, 2.0);
      expect(OnboardingVisualTokens.infoIconSize, 16.0);
      expect(OnboardingVisualTokens.infoFontSize, 12.0);
      expect(OnboardingVisualTokens.infoFontWeight, FontWeight.w500);
    });
  });
}

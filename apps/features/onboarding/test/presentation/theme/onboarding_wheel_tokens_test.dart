import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_onboarding/src/presentation/theme/onboarding_wheel_tokens.dart';

void main() {
  group('Product Onboarding wheel visual contracts', () {
    test('aliases shared core picker roles', () {
      expect(OnboardingWheelTokens.viewportHeight, TioWheelPickerTokens.viewportHeight);
      expect(OnboardingWheelTokens.selectionHeight, TioWheelPickerTokens.selectionHeight);
      expect(
        OnboardingWheelTokens.selectionHorizontalMargin,
        TioWheelPickerTokens.selectionHorizontalMargin,
      );
      expect(
        OnboardingWheelTokens.selectionSurfaceAlpha,
        TioWheelPickerTokens.selectionSurfaceAlpha,
      );
      expect(OnboardingWheelTokens.itemExtent, TioWheelPickerTokens.itemExtent);
      expect(
        OnboardingWheelTokens.selectedFontSize,
        TioWheelPickerTokens.selectedFontSize,
      );
    });

    test('keeps Onboarding-specific drum treatment', () {
      expect(OnboardingWheelTokens.perspective, 0.003);
      expect(OnboardingWheelTokens.diameterRatio, 1.6);
      expect(OnboardingWheelTokens.unselectedFontSize, 16.0);
      expect(OnboardingWheelTokens.selectedFontWeight, FontWeight.w800);
      expect(OnboardingWheelTokens.unselectedFontWeight, FontWeight.w500);
      expect(OnboardingWheelTokens.unselectedTextAlpha, 90);
      expect(OnboardingWheelTokens.standardRowHorizontalPadding, 28.0);
      expect(OnboardingWheelTokens.feetInchesRowHorizontalPadding, 36.0);
      expect(OnboardingWheelTokens.decimalSeparatorFontSize, 28.0);
      expect(OnboardingWheelTokens.decimalSeparatorFontWeight, FontWeight.w900);
      expect(OnboardingWheelTokens.selectedUnitFontSize, 18.0);
      expect(OnboardingWheelTokens.unselectedUnitFontSize, 15.0);
    });
  });
}

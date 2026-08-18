import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Product Onboarding Height/Weight drum-wheel treatment.
///
/// Cross-picker geometry aliases the shared core wheel contracts. Perspective,
/// diameter, unselected treatment and unit-row geometry remain Onboarding-owned
/// because they intentionally differ from the reusable DOB picker.
class OnboardingWheelTokens {
  const OnboardingWheelTokens._();

  static const viewportHeight = TioWheelPickerTokens.viewportHeight;
  static const selectionHeight = TioWheelPickerTokens.selectionHeight;
  static const selectionHorizontalMargin =
      TioWheelPickerTokens.selectionHorizontalMargin;
  static const selectionSurfaceAlpha = TioWheelPickerTokens.selectionSurfaceAlpha;
  static const itemExtent = TioWheelPickerTokens.itemExtent;
  static const selectedFontSize = TioWheelPickerTokens.selectedFontSize;

  static const perspective = 0.003;
  static const diameterRatio = 1.6;
  static const unselectedFontSize = 16.0;
  static const selectedFontWeight = FontWeight.w800;
  static const unselectedFontWeight = FontWeight.w500;
  static const unselectedTextAlpha = 90;

  static const standardRowHorizontalPadding = 28.0;
  static const feetInchesRowHorizontalPadding = 36.0;

  static const decimalSeparatorFontSize = 28.0;
  static const decimalSeparatorFontWeight = FontWeight.w900;

  static const selectedUnitFontSize = 18.0;
  static const unselectedUnitFontSize = 15.0;
}

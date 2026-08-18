import 'package:flutter/material.dart';

/// Product Onboarding shell-only visual contracts.
///
/// Step sequencing, profile math, transition timing calculations and controller
/// behavior intentionally remain outside the design-token layer.
class OnboardingVisualTokens {
  const OnboardingVisualTokens._();

  static const topBarHeight = 48.0;
  static const progressThickness = 4.0;
  static const contentBottomClearance = 100.0;

  static const wheelSheetDividerAlpha = 45;
  static const wheelSheetDividerWidth = 1.0;

  static const normalGradientStops = <double>[0.0, 0.25, 0.70, 1.0];
  static const normalGradientTransparentOpacity = 0.0;
  static const normalGradientMidOpacity = 0.50;
  static const normalGradientStrongOpacity = 0.95;
  static const normalGradientOpaqueOpacity = 1.0;

  static const infoTopPadding = 2.0;
  static const infoIconSize = 16.0;
  static const infoFontSize = 12.0;
  static const infoFontWeight = FontWeight.w500;
}

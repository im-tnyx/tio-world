import 'package:flutter/material.dart';

/// Presentation-only contracts for Account Setup.
///
/// Username availability, phone normalization, persistence and flow decisions
/// intentionally remain outside this design-system layer.
class AccountSetupVisualTokens {
  const AccountSetupVisualTokens._();

  static const topBarHeight = 48.0;
  static const contentMaxWidth = 480.0;
  static const footerDividerOpacity = 0.18;

  static const statusFontWeight = FontWeight.w600;

  static const busyIndicatorSize = 20.0;
  static const busyIndicatorStrokeWidth = 2.0;

  static const helperFontSize = 12.0;
  static const helperLineHeight = 1.3;
}

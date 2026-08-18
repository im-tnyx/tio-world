import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Age-verification dialog presentation contracts.
///
/// Date formatting and age eligibility behavior intentionally remain outside
/// this visual token family.
class OnboardingAgeDialogTokens {
  const OnboardingAgeDialogTokens._();

  static const panelRadius = 20.0;
  static const horizontalInset = 28.0;
  static const panelHorizontalPadding = TioSpacing.extraLarge;
  static const panelTopPadding = TioSpacing.extraLarge;
  static const panelBottomPadding = 20.0;

  static const choiceGap = TioSpacing.medium;
  static const actionHeight = 48.0;
  static const actionRadius = 30.0;
  static const outlinedActionAlpha = 90;
  static const outlinedActionWidth = 1.5;
  static const actionLabelFontSize = 15.0;
  static const actionLabelFontWeight = FontWeight.w700;

  static const primaryActionBackgroundColor = Color(0xFFFFFFFF);
  static const primaryActionForegroundColor = Color(0xFF000000);

  static const rejectionBodyLineHeight = 1.3;
}

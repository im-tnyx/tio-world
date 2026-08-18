import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Shared presentation contracts for Product Onboarding modal surfaces.
///
/// Only values proven common across the data-collection sheet and age dialogs
/// live here. Surface-specific geometry stays in the corresponding narrow token
/// family.
class OnboardingModalTokens {
  const OnboardingModalTokens._();

  static const titleFontSize = 18.0;
  static const titleFontWeight = FontWeight.w700;
  static const bodyFontSize = 14.0;

  static const titleToBodyGap = 10.0;
  static const actionTopGap = TioSpacing.extraLarge;
}

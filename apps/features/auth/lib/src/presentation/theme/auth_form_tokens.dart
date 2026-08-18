import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Shared visual contracts for the canonical Login and Sign Up form chrome.
///
/// Only values proven identical across both surfaces belong here. Input border
/// and divider details remain surface-owned until their source-of-truth audit
/// is complete.
class AuthFormTokens {
  const AuthFormTokens._();

  static const topBarHeight = 48.0;
  static const titleFontSize = 20.0;
  static const titleFontWeight = FontWeight.w700;

  static const passwordVisibilityIconSize = 22.0;

  static const socialProviderGap = TioSpacing.medium;

  static const footerFontSize = 14.0;
  static const footerLinkFontWeight = FontWeight.w700;
  static const footerLinkHorizontalPadding = TioSpacing.extraSmall;
  static const footerLinkVerticalPadding = TioSpacing.small;
}

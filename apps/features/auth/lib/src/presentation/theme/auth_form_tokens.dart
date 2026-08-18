import 'package:tio_core/core.dart';

/// Shared geometry and spacing contracts for the canonical Login and Sign Up
/// form chrome.
///
/// Typography is intentionally resolved through Theme.of(context).textTheme so
/// Auth consumes the canonical core semantic typography instead of duplicating
/// font sizes and weights here. Input border and surface-specific divider
/// details remain local until their source-of-truth audit is complete.
class AuthFormTokens {
  const AuthFormTokens._();

  static const topBarHeight = 48.0;
  static const passwordVisibilityIconSize = 22.0;

  static const dividerOpacity = 0.30;
  static const dividerHorizontalPadding = TioSpacing.large;

  static const socialProviderGap = TioSpacing.medium;

  static const footerLinkHorizontalPadding = TioSpacing.extraSmall;
  static const footerLinkVerticalPadding = TioSpacing.small;
}

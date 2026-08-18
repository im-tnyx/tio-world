import 'package:tio_core/core.dart';

/// Shared geometry and spacing contracts across canonical Auth form surfaces.
///
/// Typography is intentionally resolved through Theme.of(context).textTheme so
/// Auth consumes the canonical core semantic typography instead of duplicating
/// font sizes and weights here. Surface-specific border and divider details stay
/// local until repeated role evidence proves shared ownership.
class AuthFormTokens {
  const AuthFormTokens._();

  static const topBarHeight = 48.0;
  static const inputLeadingIconSize = 20.0;
  static const passwordVisibilityIconSize = 22.0;

  static const dividerOpacity = 0.30;
  static const dividerHorizontalPadding = TioSpacing.large;
  static const dividerLabelLetterSpacing = 1.0;

  static const socialProviderGap = TioSpacing.medium;

  static const footerLinkHorizontalPadding = TioSpacing.extraSmall;
  static const footerLinkVerticalPadding = TioSpacing.small;
}

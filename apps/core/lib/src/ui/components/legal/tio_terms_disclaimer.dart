import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Reusable legal terms and privacy policy disclaimer matching TNYX / Tio design tokens.
class TioTermsDisclaimer extends StatelessWidget {
  const TioTermsDisclaimer({
    this.prefixText = 'By continuing, you agree to our',
    this.termsText = 'Terms of Service',
    this.andText = ' and ',
    this.privacyText = 'Privacy Policy',
    this.onTermsTap,
    this.onPrivacyTap,
    this.fontSize = 12,
    this.textColor,
    this.linkColor,
    super.key,
  });

  final String prefixText;
  final String termsText;
  final String andText;
  final String privacyText;
  final VoidCallback? onTermsTap;
  final VoidCallback? onPrivacyTap;
  final double fontSize;
  final Color? textColor;
  final Color? linkColor;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    final resolvedTextColor =
        textColor ?? colors.textSecondary.withValues(alpha: 0.7);
    final resolvedLinkColor = linkColor ?? colors.textPrimary;

    final linkStyle = TextStyle(
      fontSize: fontSize,
      color: resolvedLinkColor,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: resolvedLinkColor.withValues(alpha: 0.5),
    );

    return Center(
      child: Text.rich(
        TextSpan(
          text: '$prefixText\n',
          style: TextStyle(
            fontSize: fontSize,
            color: resolvedTextColor,
            height: 1.5,
          ),
          children: [
            TextSpan(
              text: termsText,
              style: linkStyle,
              recognizer: onTermsTap != null
                  ? (TapGestureRecognizer()..onTap = onTermsTap)
                  : null,
            ),
            TextSpan(
              text: andText,
              style: TextStyle(
                fontSize: fontSize,
                color: resolvedTextColor,
              ),
            ),
            TextSpan(
              text: privacyText,
              style: linkStyle,
              recognizer: onPrivacyTap != null
                  ? (TapGestureRecognizer()..onTap = onPrivacyTap)
                  : null,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '../theme/welcome_tokens.dart';
import '../state/welcome_ui_state.dart';
import '../action/welcome_action.dart';

class WelcomeDisclaimer extends StatelessWidget {
  const WelcomeDisclaimer({
    required this.state,
    required this.onAction,
    super.key,
  });

  final WelcomeUiState state;
  final ValueChanged<WelcomeAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    final linkStyle = theme.textTheme.bodySmall?.copyWith(
      color: WelcomeColors.getAdaptivePrimary(context),
      fontWeight: FontWeight.bold,
      decoration: TextDecoration.underline,
      decorationColor: WelcomeColors.getAdaptivePrimary(context).withValues(alpha: 0.5),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: WelcomeDimens.spaceSM),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: state.termsPrefix),
            TextSpan(
              text: state.termsText,
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => onAction(const WelcomeTermsTapped()),
            ),
            TextSpan(text: state.andText),
            TextSpan(
              text: state.privacyText,
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => onAction(const WelcomePrivacyTapped()),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

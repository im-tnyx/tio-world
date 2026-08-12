import 'package:flutter/material.dart';
import '../theme/welcome_tokens.dart';
import '../state/welcome_ui_state.dart';

class WelcomeDisclaimer extends StatelessWidget {
  const WelcomeDisclaimer({
    required this.state,
    super.key,
  });

  final WelcomeUiState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final baseStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );

    final emphasisStyle = theme.textTheme.bodySmall?.copyWith(
      color: WelcomeColors.getAdaptivePrimary(context),
      fontWeight: FontWeight.bold,
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
              style: emphasisStyle,
            ),
            TextSpan(text: state.andText),
            TextSpan(
              text: state.privacyText,
              style: emphasisStyle,
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

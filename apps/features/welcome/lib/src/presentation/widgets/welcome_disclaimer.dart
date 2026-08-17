import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import '../state/welcome_ui_state.dart';

class WelcomeDisclaimer extends StatelessWidget {
  const WelcomeDisclaimer({
    required this.state,
    super.key,
  });

  final WelcomeUiState state;

  @override
  Widget build(BuildContext context) {
    return TioTermsDisclaimer(
      prefixText: state.termsPrefix,
      termsText: state.termsText,
      andText: state.andText,
      privacyText: state.privacyText,
      textColor: Colors.white.withValues(alpha: 0.7),
      linkColor: Colors.white,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import 'auth_entry_mode.dart';

/// Auth-specific composition of the reusable core round provider/mode actions.
class AuthRoundActions extends StatelessWidget {
  const AuthRoundActions({
    required this.mode,
    required this.onGooglePressed,
    required this.onTruecallerPressed,
    required this.onModeSwitchPressed,
    this.googleLoading = false,
    this.enabled = true,
    this.keyPrefix = 'auth',
    super.key,
  });

  final AuthEntryMode mode;
  final VoidCallback onGooglePressed;
  final VoidCallback onTruecallerPressed;
  final VoidCallback onModeSwitchPressed;
  final bool googleLoading;
  final bool enabled;
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    final switchToEmail = mode == AuthEntryMode.phone;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        TioSocialButton.round(
          key: ValueKey('$keyPrefix-google-round-action'),
          type: TioSocialButtonType.google,
          label: 'Google',
          enabled: enabled,
          loading: googleLoading,
          onPressed: onGooglePressed,
        ),
        TioSocialButton.round(
          key: ValueKey('$keyPrefix-truecaller-round-action'),
          type: TioSocialButtonType.truecaller,
          label: 'Truecaller',
          enabled: enabled && !googleLoading,
          onPressed: onTruecallerPressed,
        ),
        TioSocialButton.round(
          key: ValueKey('$keyPrefix-mode-round-action'),
          type: switchToEmail
              ? TioSocialButtonType.email
              : TioSocialButtonType.phone,
          label: switchToEmail ? 'Email' : 'Phone',
          enabled: enabled && !googleLoading,
          onPressed: onModeSwitchPressed,
        ),
      ],
    );
  }
}

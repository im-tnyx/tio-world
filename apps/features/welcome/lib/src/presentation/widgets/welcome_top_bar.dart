import 'package:flutter/material.dart';
import '../theme/welcome_tokens.dart';

class WelcomeTopBar extends StatelessWidget {
  const WelcomeTopBar({
    required this.localeCode,
    required this.skipText,
    required this.onSkip,
    required this.onLanguageTap,
    super.key,
  });

  final String localeCode;
  final String skipText;
  final VoidCallback onSkip;
  final VoidCallback onLanguageTap;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Language - Optimized ripple effect
        Material(
          color: WelcomeColors.transparent,
          child: InkWell(
            onTap: onLanguageTap,
            borderRadius: BorderRadius.circular(WelcomeDimens.radiusL),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WelcomeDimens.spaceXS,
                vertical: WelcomeDimens.spaceXXS,
              ),
              child: Text(
                localeCode.toUpperCase(),
                style: headerStyle,
              ),
            ),
          ),
        ),

        // Skip Button - Now matching the same ripple effect and padding as EN
        Material(
          color: WelcomeColors.transparent,
          child: InkWell(
            onTap: onSkip,
            borderRadius: BorderRadius.circular(WelcomeDimens.radiusL),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: WelcomeDimens.spaceXS,
                vertical: WelcomeDimens.spaceXXS,
              ),
              child: Text(
                skipText,
                style: headerStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

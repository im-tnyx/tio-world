import 'package:flutter/material.dart';
import '../theme/welcome_tokens.dart';

class WelcomeTopBar extends StatelessWidget {
  const WelcomeTopBar({
    required this.localeCode,
    required this.skipText,
    required this.onSkip,
    super.key,
  });

  final String localeCode;
  final String skipText;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final headerStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          color: Colors.white,
        );

    return Row(
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: WelcomeDimens.spaceXS,
              vertical: WelcomeDimens.spaceXXS,
            ),
            child: Text(
              localeCode.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: headerStyle,
            ),
          ),
        ),
        const Spacer(),
        Flexible(
          child: Material(
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: headerStyle,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

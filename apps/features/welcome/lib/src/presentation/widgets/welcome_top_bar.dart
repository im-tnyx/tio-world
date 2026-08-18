import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../theme/welcome_visual_tokens.dart';

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
          color: WelcomeColorTokens.onMediaPrimary,
        );

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TioSpacing.small,
                vertical: WelcomeLayoutTokens.topBarVerticalPadding,
              ),
              child: Text(
                localeCode.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: headerStyle,
              ),
            ),
          ),
        ),
        // Transparent Material is intentional so the InkWell renders directly
        // over the edge-to-edge hero instead of introducing a surface color.
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('welcome-skip-action'),
            onTap: onSkip,
            borderRadius: BorderRadius.circular(TioRadius.large),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: TioSpacing.small,
                vertical: WelcomeLayoutTokens.topBarVerticalPadding,
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
      ],
    );
  }
}

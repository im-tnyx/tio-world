import 'package:flutter/material.dart';

import '../theme/welcome_visual_tokens.dart';

class WelcomeFeatureTile extends StatelessWidget {
  const WelcomeFeatureTile({
    required this.title,
    required this.description,
    required this.iconWidget,
    super.key,
  });

  final String title;
  final String description;
  final Widget iconWidget;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: WelcomeLayoutTokens.featureIconBoxSize,
          height: WelcomeLayoutTokens.featureIconBoxSize,
          child: Center(child: iconWidget),
        ),
        const SizedBox(height: WelcomeLayoutTokens.featureIconToTitleGap),
        Text(
          title,
          textAlign: TextAlign.center,
          style: WelcomeTypographyTokens.featureTitle.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(
          height: WelcomeLayoutTokens.featureTitleToDescriptionGap,
        ),
        Text(
          description,
          textAlign: TextAlign.center,
          style: WelcomeTypographyTokens.featureDescription.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

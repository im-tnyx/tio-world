import 'package:flutter/material.dart';

import '../theme/welcome_visual_tokens.dart';

class WelcomeBackdrop extends StatelessWidget {
  const WelcomeBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).scaffoldBackgroundColor;
    final topOverlayColors = WelcomeBackdropTokens.topOverlayAlphas
        .map((alpha) => themeColor.withValues(alpha: alpha))
        .toList(growable: false);
    final bottomOverlayColors = WelcomeBackdropTokens.bottomOverlayAlphas
        .map((alpha) => themeColor.withValues(alpha: alpha))
        .toList(growable: false);

    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: topOverlayColors,
                stops: WelcomeBackdropTokens.topOverlayStops,
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: FractionallySizedBox(
            widthFactor: 1,
            heightFactor: WelcomeBackdropTokens.bottomCoverageFactor,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: bottomOverlayColors,
                  stops: WelcomeBackdropTokens.bottomOverlayStops,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

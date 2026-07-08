import 'package:flutter/material.dart';

class WelcomeDimens {
  WelcomeDimens._();
  static const double paddingScreen = 24.0;
  static const double spaceXS = 8.0;
  static const double spaceXXS = 4.0;
  static const double spaceS = 12.0;
  static const double spaceSM = 16.0;
  static const double spaceM = 24.0;
  static const double radiusXL = 20.0;
  static const double radiusL = 16.0;
  static const double buttonHeightLarge = 56.0;
  static const double borderThin = 1.0;
  static const double borderSubtle = 0.8;
  static const double featureTileHeight = 80.0;
  static const double featureTileIconContainerSize = 48.0;
  static const double radiusFeatureIcon = 12.0;
  static const double iconSizeXS = 20.0;
  static const double iconSizeS = 24.0;
  static const double opacityGlass = 0.08;
  static const double opacityOverlayLow = 0.1;
  static const double opacityMuted = 0.5;
}

class WelcomeColors {
  WelcomeColors._();
  static const Color transparent = Colors.transparent;
  static Color getAdaptivePrimary(BuildContext context) {
    return const Color(0xFFD4AF37); // Premium Gold color
  }
  static Color getOnSurfaceColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Colors.black;
  }
}

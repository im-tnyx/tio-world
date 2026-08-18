import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Feature-owned visual contracts for the Welcome composition.
///
/// Shared design primitives continue to come from `tio_core`. Values remain
/// here only when they express a Welcome-specific composition/style contract.
class WelcomeLayoutTokens {
  const WelcomeLayoutTokens._();

  static const heroImageHeightFactor = 0.82;
  static const heroTopFlex = 1;
  static const heroBottomFlex = 3;
  static const heroDividerWidth = 60.0;
  static const heroDividerHeight = 2.0;

  static const featurePanelRadius = 20.0;
  static const featurePanelSurfaceOpacity = 0.94;
  static const featureDividerWidth = 1.0;
  static const featureDividerHeight = 64.0;
  static const featureDividerHorizontalMargin = TioSpacing.extraSmall;

  static const featureIconBoxSize = 32.0;
  static const featureAssetWidth = 32.0;
  static const featureGlyphSize = 28.0;
  static const featureIconToTitleGap = 10.0;
  static const featureTitleToDescriptionGap = 6.0;

  static const topBarVerticalPadding = TioSpacing.extraSmall;
  static const ctaIconSize = 20.0;
}

class WelcomeMotionTokens {
  const WelcomeMotionTokens._();

  static const contentRevealStart = 0.40;
  static const contentRevealOffsetY = 30.0;
}

class WelcomeTypographyTokens {
  const WelcomeTypographyTokens._();

  static const hero = TextStyle(
    fontSize: 42.0,
    height: 1.1,
    fontWeight: FontWeight.w900,
    fontFamily: 'Roboto',
  );

  static const supporting = TextStyle(
    fontSize: 16.0,
    height: 1.4,
  );

  static const accountPrompt = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
  );

  static const loginAction = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
  );

  static const featureTitle = TextStyle(
    fontSize: 10.5,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.8,
  );

  static const featureDescription = TextStyle(
    fontSize: 9.5,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );
}

class WelcomeColorTokens {
  const WelcomeColorTokens._();

  // These are media-overlay roles, not general app semantic colors. Repository
  // audit did not show a matching cross-feature role that justified promoting
  // them into TioColors during this slice.
  static const mediaBackground = Color(0xFF000000);
  static const onMediaPrimary = Color(0xFFFFFFFF);
  static const onMediaSecondary = Color(0xB3FFFFFF);
}

class WelcomeBackdropTokens {
  const WelcomeBackdropTokens._();

  static const bottomCoverageFactor = 0.50;

  static const topOverlayAlphas = <double>[0.18, 0.08, 0.0];
  static const topOverlayStops = <double>[0.0, 0.35, 1.0];

  static const bottomOverlayAlphas = <double>[0.0, 0.30, 1.0, 1.0, 1.0, 1.0];
  static const bottomOverlayStops = <double>[0.0, 0.20, 0.50, 0.80, 0.90, 1.0];
}

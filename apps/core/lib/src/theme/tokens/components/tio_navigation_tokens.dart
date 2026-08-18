import 'package:flutter/material.dart';

import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';
import '../primitive/tio_opacity.dart';

class TioNavigationTokens {
  const TioNavigationTokens._();

  static const bottomBarHeight = 62.0;
  static const itemRadius = TioRadius.large;
  static const iconSize = 22.0;
  static const indicatorOpacity = TioOpacity.opacity14;
  static const elevation = 0.0;
  static const labelTopPadding = 2.0;

  static const topBarLeadingWidth = TioSpacing.extraLarge * 3;
  static const planPillWidth = 125.0;
  static const planPillHeight = 32.0;
  static const planIconSize = 14.0;
  static const planContentGap = TioSpacing.extraSmall;
  static const planPlusAccentColor = Color(0xFFF59E0B);

  static const aiTabActivePadding = 5.0;
  static const aiTabInactivePadding = 4.0;
  static const aiTabIconSize = 14.0;
  static const aiTabGlowOpacity = TioOpacity.opacity30;
  static const aiTabGlowBlurRadius = 6.0;
  static const aiTabGlowOffsetY = 2.0;
  static const aiTabInactiveOutlineOpacity = TioOpacity.opacity40;
  static const aiTabInactiveOutlineWidth = 1.5;
}

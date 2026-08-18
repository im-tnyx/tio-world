import '../effects/tio_elevation.dart';
import '../foundation/tio_palette.dart';
import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';
import '../foundation/tio_stroke.dart';
import '../primitive/tio_opacity.dart';
import '../primitive/tio_size.dart';

class TioNavigationTokens {
  const TioNavigationTokens._();

  static const bottomBarHeight = TioSize.dp62;
  static const itemRadius = TioRadius.lg;
  static const iconSize = TioSize.dp22;
  static const indicatorOpacity = TioOpacity.opacity14;
  static const elevation = TioElevation.none;
  static const labelTopPadding = TioSpacing.xxs;

  static const topBarLeadingWidth = TioSize.dp72;
  static const planPillWidth = TioSize.dp125;
  static const planPillHeight = TioSize.dp32;
  static const planIconSize = TioSize.dp14;
  static const planContentGap = TioSpacing.xs;
  static const planPlusAccentColor = TioPalette.amber500;

  static const aiTabActivePadding = TioSize.dp5;
  static const aiTabInactivePadding = TioSpacing.xs;
  static const aiTabIconSize = TioSize.dp14;
  static const aiTabGlowOpacity = TioOpacity.opacity30;
  static const aiTabGlowBlurRadius = TioSize.dp6;
  static const aiTabGlowOffsetY = TioSize.dp2;
  static const aiTabInactiveOutlineOpacity = TioOpacity.opacity40;
  static const aiTabInactiveOutlineWidth = TioStroke.width15;
}

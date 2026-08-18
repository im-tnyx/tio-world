import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';
import '../foundation/tio_stroke.dart';
import '../primitive/tio_opacity.dart';
import '../primitive/tio_size.dart';

class TioCardTokens {
  const TioCardTokens._();

  static const radius = TioRadius.lg;
  static const radiusItem = TioRadius.sm;
  static const padding = TioSpacing.lg;

  // Material CardTheme currently has a distinct live runtime contract from
  // TioCard. Keep it explicit and pixel-preserving until a separate visual
  // decision intentionally unifies the two card shapes.
  static const materialThemeRadius = TioSize.dp20;
  static const materialThemeElevation = 0.0;

  static const glassContainerOpacity = TioOpacity.opacity72;
  static const glassBorderOpacity = TioOpacity.opacity16;

  // Border Tokens
  static const borderThin = TioStroke.width075;
  static const borderThick = TioStroke.width125;
  static const borderBold = TioStroke.width2;

  // Aliases for Selection
  static const selectedBorderWidth = borderThick;
  static const unselectedBorderWidth = borderThin;

  static const selectedContainerAlpha = TioOpacity.opacity10;
  static const unselectedOutlineAlpha = TioOpacity.opacity40;
}

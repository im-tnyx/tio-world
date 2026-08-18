import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';

class TioCardTokens {
  const TioCardTokens._();

  static const radius = TioRadius.large;
  static const radiusItem = TioRadius.small;
  static const padding = TioSpacing.large;

  // Material CardTheme currently has a distinct live runtime contract from
  // TioCard. Keep it explicit and pixel-preserving until a separate visual
  // decision intentionally unifies the two card shapes.
  static const materialThemeRadius = 20.0;
  static const materialThemeElevation = 0.0;

  // Border Tokens
  static const borderThin = 0.75;
  static const borderThick = 1.25;
  static const borderBold = 2.0;

  // Aliases for Selection
  static const selectedBorderWidth = borderThick;
  static const unselectedBorderWidth = borderThin;

  static const selectedContainerAlpha = 0.10;
  static const unselectedOutlineAlpha = 0.40;
}

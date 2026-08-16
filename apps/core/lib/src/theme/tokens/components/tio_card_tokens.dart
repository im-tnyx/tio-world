class TioCardTokens {
  const TioCardTokens._();

  // 1:1 Exact Match with Tnyx-hub AppDimens & AppShapes
  static const radius = 16.0; // AppDimens.radiusCard (16.dp)
  static const radiusItem = 8.0; // AppDimens.radiusItem (8.dp)
  static const padding = 16.0; // AppDimens.paddingCard (16.dp)

  // Border Tokens
  static const borderThin = 0.75; // AppDimens.borderThin (0.75.dp)
  static const borderThick = 1.25; // AppDimens.borderThick (1.25.dp)
  static const borderBold = 2.0; // AppDimens.borderBold (2.0.dp)

  // Aliases for Selection
  static const selectedBorderWidth = borderThick; // 1.25
  static const unselectedBorderWidth = borderThin; // 0.75

  static const selectedContainerAlpha = 0.10; // 10% primary tint
  static const unselectedOutlineAlpha = 0.40; // 40% outline alpha
}

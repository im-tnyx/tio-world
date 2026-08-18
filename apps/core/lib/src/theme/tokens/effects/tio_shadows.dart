import 'package:flutter/material.dart';

import '../foundation/tio_palette.dart';
import 'tio_shadow_tokens.dart';

class TioShadows extends ThemeExtension<TioShadows> {
  const TioShadows({
    required this.soft,
    required this.elevatedPanelColor,
  });

  final List<BoxShadow> soft;

  /// Runtime semantic color for stronger floating/elevated panel shadows.
  ///
  /// Light, dark, and OLED intentionally preserve the same audited color for
  /// now. Keeping the role in the runtime scheme allows future theme-specific
  /// tuning without changing component code.
  final Color elevatedPanelColor;

  static const light = TioShadows(
    soft: TioShadowTokens.soft,
    elevatedPanelColor: TioPalette.blackAlpha80,
  );

  static const dark = TioShadows(
    soft: TioShadowTokens.soft,
    elevatedPanelColor: TioPalette.blackAlpha80,
  );

  static const oled = TioShadows(
    soft: TioShadowTokens.soft,
    elevatedPanelColor: TioPalette.blackAlpha80,
  );

  /// Compatibility default for callers that do not yet resolve a theme mode.
  static const standard = light;

  @override
  TioShadows copyWith({
    List<BoxShadow>? soft,
    Color? elevatedPanelColor,
  }) {
    return TioShadows(
      soft: soft ?? this.soft,
      elevatedPanelColor: elevatedPanelColor ?? this.elevatedPanelColor,
    );
  }

  @override
  TioShadows lerp(ThemeExtension<TioShadows>? other, double t) {
    if (other is! TioShadows) return this;
    return t < 0.5 ? this : other;
  }
}

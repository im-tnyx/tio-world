import 'package:flutter/material.dart';

import 'tio_shadow_tokens.dart';

class TioShadows extends ThemeExtension<TioShadows> {
  const TioShadows({required this.soft});

  final List<BoxShadow> soft;

  /// Runtime standard shadow scheme backed by the canonical static effect
  /// contract. Physical shadow values are owned by [TioShadowTokens].
  static const standard = TioShadows(soft: TioShadowTokens.soft);

  @override
  TioShadows copyWith({List<BoxShadow>? soft}) {
    return TioShadows(soft: soft ?? this.soft);
  }

  @override
  TioShadows lerp(ThemeExtension<TioShadows>? other, double t) {
    if (other is! TioShadows) return this;
    return t < 0.5 ? this : other;
  }
}

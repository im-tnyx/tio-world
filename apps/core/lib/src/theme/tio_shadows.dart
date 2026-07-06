import 'package:flutter/material.dart';

class TioShadows extends ThemeExtension<TioShadows> {
  const TioShadows({required this.soft});

  final List<BoxShadow> soft;

  static const standard = TioShadows(
    soft: [
      BoxShadow(
        blurRadius: 24,
        offset: Offset(0, 12),
        color: Color(0x1A000000),
      ),
    ],
  );

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

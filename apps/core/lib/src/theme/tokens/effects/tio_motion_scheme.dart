import 'package:flutter/material.dart';

import 'tio_motion.dart';

class TioMotionScheme extends ThemeExtension<TioMotionScheme> {
  const TioMotionScheme({
    required this.reducedMotion,
    required this.fast,
    required this.normal,
    required this.slow,
  });

  const TioMotionScheme.standard()
      : reducedMotion = false,
        fast = const Duration(milliseconds: TioMotion.fastMs),
        normal = const Duration(milliseconds: TioMotion.normalMs),
        slow = const Duration(milliseconds: TioMotion.slowMs);

  const TioMotionScheme.reduced()
      : reducedMotion = true,
        fast = Duration.zero,
        normal = Duration.zero,
        slow = Duration.zero;

  final bool reducedMotion;
  final Duration fast;
  final Duration normal;
  final Duration slow;

  @override
  TioMotionScheme copyWith({
    bool? reducedMotion,
    Duration? fast,
    Duration? normal,
    Duration? slow,
  }) {
    return TioMotionScheme(
      reducedMotion: reducedMotion ?? this.reducedMotion,
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
    );
  }

  @override
  TioMotionScheme lerp(
    covariant ThemeExtension<TioMotionScheme>? other,
    double t,
  ) {
    if (other is! TioMotionScheme) return this;
    return TioMotionScheme(
      reducedMotion: t < 0.5 ? reducedMotion : other.reducedMotion,
      fast: _lerpDuration(fast, other.fast, t),
      normal: _lerpDuration(normal, other.normal, t),
      slow: _lerpDuration(slow, other.slow, t),
    );
  }

  static Duration _lerpDuration(Duration from, Duration to, double t) {
    return Duration(
      microseconds:
          (from.inMicroseconds + (to.inMicroseconds - from.inMicroseconds) * t)
              .round(),
    );
  }
}

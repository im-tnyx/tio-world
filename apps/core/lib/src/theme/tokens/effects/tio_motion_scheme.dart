import 'package:flutter/material.dart';

import 'tio_motion.dart';

class TioMotionScheme extends ThemeExtension<TioMotionScheme> {
  const TioMotionScheme({
    required this.reducedMotion,
    required this.fast,
    required this.normal,
    required this.slow,
    required this.fadeThroughEnter,
    required this.fadeThroughExit,
    required this.progress,
  });

  const TioMotionScheme.standard()
      : reducedMotion = false,
        fast = const Duration(milliseconds: TioMotion.fastMs),
        normal = const Duration(milliseconds: TioMotion.normalMs),
        slow = const Duration(milliseconds: TioMotion.slowMs),
        fadeThroughEnter = const Duration(
          milliseconds: TioMotion.fadeThroughEnterMs,
        ),
        fadeThroughExit = const Duration(
          milliseconds: TioMotion.fadeThroughExitMs,
        ),
        progress = const Duration(milliseconds: TioMotion.progressMs);

  const TioMotionScheme.reduced()
      : reducedMotion = true,
        fast = Duration.zero,
        normal = Duration.zero,
        slow = Duration.zero,
        fadeThroughEnter = Duration.zero,
        fadeThroughExit = Duration.zero,
        progress = Duration.zero;

  final bool reducedMotion;
  final Duration fast;
  final Duration normal;
  final Duration slow;
  final Duration fadeThroughEnter;
  final Duration fadeThroughExit;
  final Duration progress;

  @override
  TioMotionScheme copyWith({
    bool? reducedMotion,
    Duration? fast,
    Duration? normal,
    Duration? slow,
    Duration? fadeThroughEnter,
    Duration? fadeThroughExit,
    Duration? progress,
  }) {
    return TioMotionScheme(
      reducedMotion: reducedMotion ?? this.reducedMotion,
      fast: fast ?? this.fast,
      normal: normal ?? this.normal,
      slow: slow ?? this.slow,
      fadeThroughEnter: fadeThroughEnter ?? this.fadeThroughEnter,
      fadeThroughExit: fadeThroughExit ?? this.fadeThroughExit,
      progress: progress ?? this.progress,
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
      fadeThroughEnter: _lerpDuration(
        fadeThroughEnter,
        other.fadeThroughEnter,
        t,
      ),
      fadeThroughExit: _lerpDuration(
        fadeThroughExit,
        other.fadeThroughExit,
        t,
      ),
      progress: _lerpDuration(progress, other.progress, t),
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

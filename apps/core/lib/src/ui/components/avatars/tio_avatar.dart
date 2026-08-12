import 'package:flutter/material.dart';

import '../../../theme/locals/tio_theme_context.dart';
import '../../../theme/tokens/components/tio_avatar_tokens.dart';

enum TioAvatarSize {
  compact,
  small,
  medium,
  large,
  extraLarge;

  double get dimension => switch (this) {
        TioAvatarSize.compact => TioAvatarTokens.compactSize,
        TioAvatarSize.small => TioAvatarTokens.smallSize,
        TioAvatarSize.medium => TioAvatarTokens.mediumSize,
        TioAvatarSize.large => TioAvatarTokens.largeSize,
        TioAvatarSize.extraLarge => TioAvatarTokens.extraLargeSize,
      };
}

enum TioAvatarShape { circle, rounded }

enum TioAvatarFrame { none, plusRing, proHexagon }

class TioAvatar extends StatelessWidget {
  const TioAvatar({
    super.key,
    this.size = TioAvatarSize.medium,
    this.shape = TioAvatarShape.circle,
    this.frame = TioAvatarFrame.none,
    this.image,
    this.initials,
    this.fallbackIcon = Icons.person,
    this.semanticLabel,
  }) : assert(initials == null || initials.length <= 2);

  final TioAvatarSize size;
  final TioAvatarShape shape;
  final TioAvatarFrame frame;
  final ImageProvider<Object>? image;
  final String? initials;
  final IconData fallbackIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final dimension = size.dimension;
    final effectiveFrame =
        size == TioAvatarSize.extraLarge ? TioAvatarFrame.none : frame;
    final borderRadius = BorderRadius.circular(
      dimension * TioAvatarTokens.roundedRadiusFactor,
    );
    final fallback = _AvatarFallback(
      dimension: dimension,
      initials: initials,
      fallbackIcon: fallbackIcon,
    );
    final content = image == null
        ? fallback
        : Image(
            image: image!,
            width: dimension,
            height: dimension,
            fit: BoxFit.cover,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stackTrace) => fallback,
          );
    final unframedContent = switch (shape) {
      TioAvatarShape.circle => ClipOval(child: content),
      TioAvatarShape.rounded =>
        ClipRRect(borderRadius: borderRadius, child: content),
    };
    final framedContent = switch (effectiveFrame) {
      TioAvatarFrame.none => unframedContent,
      TioAvatarFrame.plusRing => DecoratedBox(
          key: const ValueKey('tio-avatar-plus-ring'),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [colors.info, colors.progress],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(TioAvatarTokens.plusRingWidth),
            child: ClipOval(child: content),
          ),
        ),
      TioAvatarFrame.proHexagon => CustomPaint(
          key: const ValueKey('tio-avatar-pro-hexagon'),
          foregroundPainter: _HexagonFramePainter(
            startColor: colors.primary,
            endColor: colors.progress,
          ),
          child: Padding(
            padding: const EdgeInsets.all(TioAvatarTokens.proFrameWidth),
            child: ClipPath(
              clipper: const _HexagonClipper(),
              child: content,
            ),
          ),
        ),
    };
    final visual = SizedBox.square(
      dimension: dimension,
      child: framedContent,
    );

    if (semanticLabel case final label?) {
      return Semantics(
        image: true,
        label: label,
        child: ExcludeSemantics(child: visual),
      );
    }
    return ExcludeSemantics(child: visual);
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  const _HexagonClipper();

  @override
  Path getClip(Size size) => _hexagonPath(size);

  @override
  bool shouldReclip(_HexagonClipper oldClipper) => false;
}

class _HexagonFramePainter extends CustomPainter {
  const _HexagonFramePainter({
    required this.startColor,
    required this.endColor,
  });

  final Color startColor;
  final Color endColor;

  @override
  void paint(Canvas canvas, Size size) {
    const frameWidth = TioAvatarTokens.proFrameWidth;
    final framePath = _hexagonPath(size, inset: frameWidth / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = frameWidth
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        colors: [startColor, endColor],
      ).createShader(Offset.zero & size);

    canvas.drawPath(framePath, paint);
  }

  @override
  bool shouldRepaint(_HexagonFramePainter oldDelegate) {
    return startColor != oldDelegate.startColor ||
        endColor != oldDelegate.endColor;
  }
}

Path _hexagonPath(Size size, {double inset = 0}) {
  final left = inset;
  final top = inset;
  final right = size.width - inset;
  final bottom = size.height - inset;
  final middleX = size.width / 2;
  final quarterHeight = (bottom - top) / 4;

  return Path()
    ..moveTo(middleX, top)
    ..lineTo(right, top + quarterHeight)
    ..lineTo(right, bottom - quarterHeight)
    ..lineTo(middleX, bottom)
    ..lineTo(left, bottom - quarterHeight)
    ..lineTo(left, top + quarterHeight)
    ..close();
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback({
    required this.dimension,
    required this.initials,
    required this.fallbackIcon,
  });

  final double dimension;
  final String? initials;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final displayInitials = initials?.trim().toUpperCase();

    return ColoredBox(
      color: colors.surfaceRaised,
      child: Center(
        child: displayInitials == null || displayInitials.isEmpty
            ? Icon(
                fallbackIcon,
                size: dimension * TioAvatarTokens.iconSizeFactor,
                color: colors.textSecondary,
              )
            : Text(
                displayInitials,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.textPrimary,
                      fontSize: dimension * TioAvatarTokens.textSizeFactor,
                    ),
              ),
      ),
    );
  }
}

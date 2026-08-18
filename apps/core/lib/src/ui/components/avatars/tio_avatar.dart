import 'package:flutter/material.dart';

import '../../../theme/context/tio_theme_context.dart';
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

enum TioAvatarShape { circle, rounded, square }

enum TioAvatarFrame { none, plusRing, proHexagon }

class TioAvatar extends StatelessWidget {
  const TioAvatar({
    super.key,
    this.size = TioAvatarSize.medium,
    this.shape = TioAvatarShape.circle,
    this.frame = TioAvatarFrame.none,
    this.imageUrl,
    this.displayName,
    @Deprecated('Use imageUrl instead') this.image,
    @Deprecated('Use displayName instead') this.initials,
    this.fallbackIcon = Icons.person,
    this.semanticLabel,
    this.customDimension,
  });

  final TioAvatarSize size;
  final TioAvatarShape shape;
  final TioAvatarFrame frame;
  final String? imageUrl;
  final String? displayName;
  final ImageProvider<Object>? image;
  final String? initials;
  final IconData fallbackIcon;
  final String? semanticLabel;
  final double? customDimension;

  String? _getInitials(String? name, String? legacyInitials) {
    final effectiveName = name ?? legacyInitials;
    if (effectiveName == null || effectiveName.trim().isEmpty) return null;

    final clean = effectiveName.trim().replaceAll('@', '');
    final parts = clean.split(RegExp(r'\s+'));

    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final dimension = customDimension ?? size.dimension;

    final effectiveFrame =
        (size == TioAvatarSize.extraLarge || shape == TioAvatarShape.square)
            ? TioAvatarFrame.none
            : frame;

    final borderRadius = BorderRadius.circular(
      dimension * TioAvatarTokens.roundedRadiusFactor,
    );

    final effectiveImageUrl = imageUrl ?? (image is NetworkImage ? (image as NetworkImage).url : null);

    final hasValidUrl = effectiveImageUrl != null &&
                       effectiveImageUrl.trim().isNotEmpty &&
                       effectiveImageUrl.trim().startsWith('http');

    final fallback = _AvatarFallback(
      dimension: dimension,
      initials: _getInitials(displayName, initials),
      fallbackIcon: fallbackIcon,
    );

    final content = (image != null && image is! NetworkImage)
        ? Image(
            image: image!,
            width: dimension,
            height: dimension,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => fallback,
          )
        : (!hasValidUrl
            ? fallback
            : Image.network(
                effectiveImageUrl.trim(),
                width: dimension,
                height: dimension,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                excludeFromSemantics: true,
                errorBuilder: (context, error, stackTrace) => fallback,
              ));
    final unframedContent = switch (shape) {
      TioAvatarShape.circle => ClipOval(key: const ValueKey('tio-avatar-circle-clip'), child: content),
      TioAvatarShape.rounded =>
        ClipRRect(borderRadius: borderRadius, child: content),
      TioAvatarShape.square => content,
    };
    final framedContent = switch (effectiveFrame) {
      TioAvatarFrame.none => unframedContent,
      TioAvatarFrame.plusRing => Builder(
        builder: (context) {
          final isSmall = dimension <= TioAvatarTokens.smallSize;
          final ringWidth = isSmall ? 1.5 : TioAvatarTokens.plusRingWidth;
          final gapWidth = isSmall ? 2.0 : 4.0;

          return DecoratedBox(
            key: const ValueKey('tio-avatar-plus-ring'),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [colors.info, colors.progress],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(ringWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.background,
                ),
                child: Padding(
                  padding: EdgeInsets.all(gapWidth),
                  child: ClipOval(child: content),
                ),
              ),
            ),
          );
        },
      ),
      TioAvatarFrame.proHexagon => CustomPaint(
          key: const ValueKey('tio-avatar-pro-hexagon'),
          foregroundPainter: _HexagonFramePainter(
            startColor: colors.primary,
            endColor: colors.progress,
            strokeWidth: dimension <= TioAvatarTokens.smallSize ? 1.5 : TioAvatarTokens.proFrameWidth,
          ),
          child: Padding(
            padding: EdgeInsets.all(
              dimension <= TioAvatarTokens.smallSize ? 2.0 : TioAvatarTokens.proFrameWidth,
            ),
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
    required this.strokeWidth,
  });

  final Color startColor;
  final Color endColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final frameWidth = strokeWidth;
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
        endColor != oldDelegate.endColor ||
        strokeWidth != oldDelegate.strokeWidth;
  }
}

Path _hexagonPath(Size size, {double inset = 0}) {
  final w = size.width;
  final h = size.height;
  final centerX = w / 2;
  final centerY = h / 2;

  // Visual correction: Hexagons look smaller than circles of the same diameter.
  // We use the full available square dimension to maximize visual size.
  final availableDim = (w < h ? w : h) - 2 * inset;

  // For Pointy Top, the height is the diameter (availableDim)
  final radius = availableDim / 2;
  final wOff = radius * 0.866; // Standard regular hexagon width factor
  final hOff = radius * 0.5;

  return Path()
    ..moveTo(centerX, centerY - radius) // Top Center
    ..lineTo(centerX + wOff, centerY - hOff) // Top Right
    ..lineTo(centerX + wOff, centerY + hOff) // Bottom Right
    ..lineTo(centerX, centerY + radius) // Bottom Center
    ..lineTo(centerX - wOff, centerY + hOff) // Bottom Left
    ..lineTo(centerX - wOff, centerY - hOff) // Top Left
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

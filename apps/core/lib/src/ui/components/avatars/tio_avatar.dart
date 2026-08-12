import 'package:flutter/material.dart';

import '../../../theme/locals/tio_theme_context.dart';
import '../../../theme/tokens/components/tio_avatar_tokens.dart';

enum TioAvatarSize {
  compact,
  small,
  medium,
  large;

  double get dimension => switch (this) {
        TioAvatarSize.compact => TioAvatarTokens.compactSize,
        TioAvatarSize.small => TioAvatarTokens.smallSize,
        TioAvatarSize.medium => TioAvatarTokens.mediumSize,
        TioAvatarSize.large => TioAvatarTokens.largeSize,
      };
}

enum TioAvatarShape { circle, rounded }

class TioAvatar extends StatelessWidget {
  const TioAvatar({
    super.key,
    this.size = TioAvatarSize.medium,
    this.shape = TioAvatarShape.circle,
    this.image,
    this.initials,
    this.fallbackIcon = Icons.person,
    this.semanticLabel,
  }) : assert(initials == null || initials.length <= 2);

  final TioAvatarSize size;
  final TioAvatarShape shape;
  final ImageProvider<Object>? image;
  final String? initials;
  final IconData fallbackIcon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final dimension = size.dimension;
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
    final clippedContent = switch (shape) {
      TioAvatarShape.circle => ClipOval(child: content),
      TioAvatarShape.rounded =>
        ClipRRect(borderRadius: borderRadius, child: content),
    };
    final visual = SizedBox.square(
      dimension: dimension,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          shape: shape == TioAvatarShape.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
          borderRadius: shape == TioAvatarShape.rounded ? borderRadius : null,
          border: Border.all(
            color: colors.surfaceVariant,
            width: TioAvatarTokens.borderWidth,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(TioAvatarTokens.borderWidth),
          child: clippedContent,
        ),
      ),
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

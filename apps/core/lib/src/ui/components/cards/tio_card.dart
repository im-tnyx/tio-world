import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

enum TioCardVariant { surface, elevated, glass, outlined, normal }

class TioCard extends StatelessWidget {
  const TioCard({
    required this.child,
    super.key,
    this.variant = TioCardVariant.surface,
    this.padding,
    this.onTap,
  });

  final Widget child;
  final TioCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final radius = BorderRadius.circular(TioCardTokens.radius);
    final background = switch (variant) {
      TioCardVariant.glass => colors.surfaceRaised.withValues(
          alpha: TioCardTokens.glassContainerOpacity,
        ),
      // Transparent is intentional: outlined cards have no fill.
      TioCardVariant.outlined => Colors.transparent,
      TioCardVariant.normal => colors.surfaceRaised,
      _ => colors.surface,
    };

    final border = switch (variant) {
      TioCardVariant.outlined => Border.all(color: colors.outlineStrong),
      TioCardVariant.glass => Border.all(
          color: colors.textPrimary.withValues(
            alpha: TioCardTokens.glassBorderOpacity,
          ),
        ),
      _ => null,
    };

    final content = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: border,
        boxShadow: variant == TioCardVariant.elevated
            ? context.tioShadows.soft
            : null,
      ),
      padding: padding ?? const EdgeInsets.all(TioCardTokens.padding),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      // Transparent is intentional: Material only hosts the InkWell ripple.
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

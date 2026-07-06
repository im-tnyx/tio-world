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
    final colors = TioTheme.colors(context);
    final radius = BorderRadius.circular(TioTheme.radius.large);
    final background = switch (variant) {
      TioCardVariant.glass => colors.surfaceRaised.withValues(alpha: 0.72),
      TioCardVariant.outlined => Colors.transparent,
      TioCardVariant.normal => colors.surfaceRaised,
      _ => colors.surface,
    };

    final border = variant == TioCardVariant.outlined || variant == TioCardVariant.glass
        ? Border.all(color: colors.textPrimary.withValues(alpha: 0.16))
        : null;

    final content = Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: border,
        boxShadow: variant == TioCardVariant.elevated ? TioTheme.shadows(context).soft : null,
      ),
      padding: padding ?? EdgeInsets.all(TioTheme.spacing.large),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

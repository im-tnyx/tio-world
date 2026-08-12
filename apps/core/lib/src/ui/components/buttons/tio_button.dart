import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

enum TioButtonVariant { primary, secondary, ghost }

class TioButton extends StatelessWidget {
  const TioButton({
    required this.label,
    required this.onPressed,
    super.key,
    this.variant = TioButtonVariant.primary,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  });

  const TioButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.primary;

  const TioButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.secondary;

  const TioButton.ghost({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.loading = false,
    this.loadingLabel,
    this.semanticLabel,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final TioButtonVariant variant;
  final bool enabled;
  final bool expand;
  final bool loading;
  final String? loadingLabel;
  final String? semanticLabel;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final motion = context.tioMotion;
    final callback = enabled && !loading ? onPressed : null;
    final indicatorColor =
        variant == TioButtonVariant.primary ? colors.onPrimary : colors.primary;
    final loadingStyle = loading ? _loadingStyle(variant, colors) : null;
    final content = AnimatedSwitcher(
      duration: motion.fast,
      child: loading
          ? _LoadingContent(
              key: const ValueKey('loading'),
              label: loadingLabel ?? label,
              indicatorColor: indicatorColor,
              reducedMotion: motion.reducedMotion,
            )
          : _ButtonContent(
              key: const ValueKey('content'),
              label: label,
              leading: leading,
              trailing: trailing,
            ),
    );
    final widthWrapper =
        expand ? SizedBox(width: double.infinity, child: content) : content;
    final button = switch (variant) {
      TioButtonVariant.primary => FilledButton(
          onPressed: callback,
          style: loadingStyle,
          child: widthWrapper,
        ),
      TioButtonVariant.secondary => OutlinedButton(
          onPressed: callback,
          style: loadingStyle,
          child: widthWrapper,
        ),
      TioButtonVariant.ghost => TextButton(
          onPressed: callback,
          style: loadingStyle,
          child: widthWrapper,
        ),
    };

    return Semantics(
      button: true,
      enabled: callback != null,
      label: semanticLabel ?? label,
      value: loading ? 'Loading' : null,
      liveRegion: loading,
      onTap: callback,
      child: ExcludeSemantics(child: button),
    );
  }
}

ButtonStyle _loadingStyle(TioButtonVariant variant, TioColors colors) {
  return switch (variant) {
    TioButtonVariant.primary => ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(colors.primary),
        foregroundColor: WidgetStatePropertyAll(colors.onPrimary),
      ),
    TioButtonVariant.secondary => ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(colors.primary),
        side: WidgetStatePropertyAll(
          BorderSide(
            color: colors.primary,
            width: TioButtonTokens.outlineWidth,
          ),
        ),
      ),
    TioButtonVariant.ghost => ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(colors.primary),
      ),
  };
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    super.key,
    this.leading,
    this.trailing,
  });

  final String label;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: TioButtonTokens.contentGap),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (trailing != null) ...[
          const SizedBox(width: TioButtonTokens.contentGap),
          trailing!,
        ],
      ],
    );
  }
}

class _LoadingContent extends StatelessWidget {
  const _LoadingContent({
    required this.label,
    required this.indicatorColor,
    required this.reducedMotion,
    super.key,
  });

  final String label;
  final Color indicatorColor;
  final bool reducedMotion;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (reducedMotion)
          Icon(
            Icons.hourglass_top,
            size: TioButtonTokens.loadingIndicatorSize,
            color: indicatorColor,
          )
        else
          SizedBox.square(
            dimension: TioButtonTokens.loadingIndicatorSize,
            child: CircularProgressIndicator(
              strokeWidth: TioButtonTokens.loadingIndicatorStrokeWidth,
              color: indicatorColor,
            ),
          ),
        const SizedBox(width: TioButtonTokens.contentGap),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}

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
    this.leading,
    this.trailing,
  });

  const TioButton.primary({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.primary;

  const TioButton.secondary({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.secondary;

  const TioButton.ghost({
    required this.label,
    required this.onPressed,
    super.key,
    this.enabled = true,
    this.expand = false,
    this.leading,
    this.trailing,
  }) : variant = TioButtonVariant.ghost;

  final String label;
  final VoidCallback? onPressed;
  final TioButtonVariant variant;
  final bool enabled;
  final bool expand;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final child = _ButtonContent(label: label, leading: leading, trailing: trailing);
    final callback = enabled ? onPressed : null;
    final widthWrapper = expand ? SizedBox(width: double.infinity, child: child) : child;

    return switch (variant) {
      TioButtonVariant.primary => FilledButton(onPressed: callback, child: widthWrapper),
      TioButtonVariant.secondary => OutlinedButton(onPressed: callback, child: widthWrapper),
      TioButtonVariant.ghost => TextButton(onPressed: callback, child: widthWrapper),
    };
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({required this.label, this.leading, this.trailing});

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
          SizedBox(width: TioTheme.spacing.small),
        ],
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        if (trailing != null) ...[
          SizedBox(width: TioTheme.spacing.small),
          trailing!,
        ],
      ],
    );
  }
}

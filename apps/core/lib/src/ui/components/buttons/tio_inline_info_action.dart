import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Compact contextual information action shared across feature footers.
///
/// This intentionally does not inherit the global [TextButton] minimum height;
/// the visual contract matches the existing Product Onboarding info treatment.
class TioInlineInfoAction extends StatelessWidget {
  const TioInlineInfoAction({
    required this.label,
    required this.onTap,
    super.key,
    this.icon = Icons.info_outline,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final enabled = onTap != null;
    final contentColor = enabled ? colors.textSecondary : colors.textMuted;

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.only(
            top: TioSize.dp2,
            bottom: TioSpacing.sm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: TioSize.dp16,
                color: contentColor,
              ),
              const SizedBox(width: TioSpacing.sm),
              Text(
                label,
                style: TextStyle(
                  fontSize: TioFontSize.size12,
                  fontWeight: TioFontWeight.w500,
                  color: contentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../buttons/buttons.dart';
import 'tio_card.dart';

/// Reusable themed confirmation surface for actions that need an explicit
/// confirm/cancel choice.
///
/// Product-specific copy and behavior stay with the feature that presents the
/// card. This component only owns the shared visual composition.
class TioConfirmationCard extends StatelessWidget {
  const TioConfirmationCard({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    super.key,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    return TioCard(
      variant: TioCardVariant.elevated,
      padding: const EdgeInsets.all(TioSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(
                color: colors.textPrimary,
                size: TioSize.dp24,
              ),
              child: icon!,
            ),
            const SizedBox(height: TioSpacing.md),
          ],
          Text(
            title,
            style: textTheme.titleLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: TioFontWeight.w700,
            ),
          ),
          const SizedBox(height: TioSpacing.sm),
          Text(
            message,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: TioLineHeight.height140,
            ),
          ),
          const SizedBox(height: TioSpacing.xl),
          Row(
            children: [
              Expanded(
                child: TioButton.secondary(
                  label: cancelLabel,
                  onPressed: onCancel,
                  expand: true,
                ),
              ),
              const SizedBox(width: TioSpacing.md),
              Expanded(
                child: TioButton.primary(
                  label: confirmLabel,
                  onPressed: onConfirm,
                  expand: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

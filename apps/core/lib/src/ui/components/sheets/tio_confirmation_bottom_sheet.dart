import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../buttons/buttons.dart';
import '../cards/tio_card.dart';

enum TioConfirmationIntent { standard, destructive }

/// Presents the reusable confirmation interaction in the standard modal shell.
///
/// The presenter owns confirm/cancel result semantics and composes its visual
/// surface from the base [TioCard] and semantic [TioButton] variants. It does
/// not expose a workflow-shaped confirmation-card component.
Future<bool?> showTioConfirmationBottomSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  Key? cardKey,
  Widget? icon,
  TioConfirmationIntent intent = TioConfirmationIntent.standard,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.lg),
        child: _TioConfirmationContent(
          key: cardKey,
          icon: icon,
          title: title,
          message: message,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          intent: intent,
          onCancel: () => Navigator.of(sheetContext).pop(false),
          onConfirm: () => Navigator.of(sheetContext).pop(true),
        ),
      ),
    ),
  );
}

class _TioConfirmationContent extends StatelessWidget {
  const _TioConfirmationContent({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onConfirm,
    required this.onCancel,
    required this.intent,
    super.key,
    this.icon,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final Widget? icon;
  final TioConfirmationIntent intent;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;

    final confirmButton = switch (intent) {
      TioConfirmationIntent.standard => TioButton.primary(
          label: confirmLabel,
          onPressed: onConfirm,
          expand: true,
        ),
      TioConfirmationIntent.destructive => TioButton.destructive(
          label: confirmLabel,
          onPressed: onConfirm,
          expand: true,
        ),
    };

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
              Expanded(child: confirmButton),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../buttons/tio_button.dart';
import 'tio_sheet.dart';

/// Presents standard explanatory content with an explicit dismissal action.
Future<void> showTioInformationBottomSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String actionLabel,
  Key? sheetKey,
  IconData? icon,
  Color? iconColor,
  TextAlign messageTextAlign = TextAlign.start,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: TioInformationBottomSheet(
          key: sheetKey,
          title: title,
          message: message,
          actionLabel: actionLabel,
          icon: icon,
          iconColor: iconColor,
          messageTextAlign: messageTextAlign,
          onDismiss: () => Navigator.of(sheetContext).pop(),
        ),
      ),
    ),
  );
}

/// Reusable content surface for explanatory bottom sheets.
class TioInformationBottomSheet extends StatelessWidget {
  const TioInformationBottomSheet({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onDismiss,
    super.key,
    this.icon,
    this.iconColor,
    this.messageTextAlign = TextAlign.start,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onDismiss;
  final IconData? icon;
  final Color? iconColor;
  final TextAlign messageTextAlign;

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final isCentered = messageTextAlign == TextAlign.center;

    return TioSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isCentered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: iconColor ?? colors.primary),
                const SizedBox(width: TioSpacing.sm),
              ],
              Expanded(
                child: Text(
                  title,
                  textAlign: isCentered ? TextAlign.center : TextAlign.start,
                  style: textTheme.titleLarge?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: onDismiss,
                icon: Icon(Icons.close_rounded, color: colors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: TioSpacing.md),
          Text(
            message,
            textAlign: messageTextAlign,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.textSecondary,
              height: TioLineHeight.height140,
            ),
          ),
          const SizedBox(height: TioSpacing.xl),
          TioButton.primary(
            label: actionLabel,
            expand: true,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

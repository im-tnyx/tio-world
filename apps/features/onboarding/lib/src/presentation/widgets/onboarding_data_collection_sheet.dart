import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

Future<void> showOnboardingDataCollectionSheet({
  required BuildContext context,
  required String body,
  String title = 'Data Collection',
}) {
  final colors = context.tioColors;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: colors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TioRadius.lg),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.xl,
          vertical: TioSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: TioFontSize.size18,
                      fontWeight: TioFontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: colors.textSecondary),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                ),
              ],
            ),
            const SizedBox(height: TioSpacing.md),
            Text(
              body,
              style: TextStyle(
                fontSize: TioFontSize.size14,
                height: TioLineHeight.height150,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: TioSpacing.xl),
            TioButton.primary(
              label: 'Understood',
              expand: true,
              onPressed: () => Navigator.of(sheetContext).pop(),
            ),
          ],
        ),
      ),
    ),
  );
}

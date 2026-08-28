import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../cards/tio_confirmation_card.dart';

/// Presents a themed confirmation card in the standard modal sheet shell.
Future<bool?> showTioConfirmationBottomSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  Key? cardKey,
  Widget? icon,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: TioPalette.transparent,
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(TioSpacing.lg),
        child: TioConfirmationCard(
          key: cardKey,
          icon: icon,
          title: title,
          message: message,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          onCancel: () => Navigator.of(sheetContext).pop(false),
          onConfirm: () => Navigator.of(sheetContext).pop(true),
        ),
      ),
    ),
  );
}

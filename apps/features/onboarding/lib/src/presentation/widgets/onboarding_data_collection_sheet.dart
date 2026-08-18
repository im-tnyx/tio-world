import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../theme/onboarding_data_sheet_tokens.dart';
import '../theme/onboarding_modal_tokens.dart';

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
        top: Radius.circular(TioRadius.large),
      ),
    ),
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: TioSpacing.extraLarge,
          vertical: TioSpacing.large,
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
                      fontSize: OnboardingModalTokens.titleFontSize,
                      fontWeight: OnboardingModalTokens.titleFontWeight,
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
            const SizedBox(height: TioSpacing.medium),
            Text(
              body,
              style: TextStyle(
                fontSize: OnboardingModalTokens.bodyFontSize,
                height: OnboardingDataSheetTokens.bodyLineHeight,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: OnboardingModalTokens.actionTopGap),
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

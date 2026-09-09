import 'package:flutter/material.dart';
import '../../../theme/theme.dart';
import '../buttons/buttons.dart';

/// Displays the modal bottom sheet for confirming image removal.
///
/// Features:
/// - Top-right circular close button
/// - "Remove Image" headline
/// - "Are you sure you want to remove this image?" description
/// - Full-width destructive "Remove" action
/// - Full-width secondary "Cancel" action
///
/// Both actions are [TioButton]s. The sheet owns its shell, copy and result
/// semantics; the shared button family owns action geometry and colour, so
/// the destructive role is selected here rather than rebuilt here.
Future<bool?> showTioRemoveImageConfirmationBottomSheet(BuildContext context) {
  final colors = context.tioColors;

  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: colors.surfaceRaised,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(TioRemoveImageSheetTokens.sheetRadius),
      ),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            TioRemoveImageSheetTokens.contentHorizontalPadding,
            TioRemoveImageSheetTokens.contentTopPadding,
            TioRemoveImageSheetTokens.contentHorizontalPadding,
            TioRemoveImageSheetTokens.contentBottomPadding,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(false),
                  child: Container(
                    width: TioRemoveImageSheetTokens.closeButtonSize,
                    height: TioRemoveImageSheetTokens.closeButtonSize,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      size: TioRemoveImageSheetTokens.closeIconSize,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: TioRemoveImageSheetTokens.closeToTitleGap,
              ),
              Text(
                'Remove Image',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: TioFontWeight.w800,
                  fontSize: TioRemoveImageSheetTokens.titleFontSize,
                  letterSpacing: TioRemoveImageSheetTokens.titleLetterSpacing,
                ),
              ),
              const SizedBox(
                height: TioRemoveImageSheetTokens.titleToSubtitleGap,
              ),
              Text(
                'Are you sure you want to remove this image?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textMuted,
                  fontSize: TioRemoveImageSheetTokens.subtitleFontSize,
                  fontWeight: TioFontWeight.w500,
                ),
              ),
              const SizedBox(
                height: TioRemoveImageSheetTokens.subtitleToActionsGap,
              ),
              // Icon colour is deliberately not set: the shared button
              // resolves it from the variant's foreground, so the destructive
              // and secondary roles stay consistent across every theme.
              TioButton.destructive(
                label: 'Remove',
                expand: true,
                trailing: const Icon(
                  Icons.delete_outline_rounded,
                  size: TioRemoveImageSheetTokens.removeIconSize,
                ),
                onPressed: () => Navigator.of(sheetContext).pop(true),
              ),
              const SizedBox(height: TioRemoveImageSheetTokens.actionGap),
              TioButton.secondary(
                label: 'Cancel',
                expand: true,
                trailing: const Icon(
                  Icons.close_rounded,
                  size: TioRemoveImageSheetTokens.cancelIconSize,
                ),
                onPressed: () => Navigator.of(sheetContext).pop(false),
              ),
            ],
          ),
        ),
      );
    },
  );
}

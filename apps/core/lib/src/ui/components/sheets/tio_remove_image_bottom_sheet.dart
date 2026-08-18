import 'package:flutter/material.dart';
import '../../../theme/theme.dart';

/// Displays the exact modal bottom sheet for confirming image removal.
///
/// Features:
/// - Top-right circular close button
/// - "Remove Image" headline
/// - "Are you sure you want to remove this image?" description
/// - Full-width "Remove 🗑️" capsule button
/// - Full-width "Cancel ✕" capsule button
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
                  fontWeight: FontWeight.w800,
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(
                height: TioRemoveImageSheetTokens.subtitleToActionsGap,
              ),
              InkWell(
                onTap: () => Navigator.of(sheetContext).pop(true),
                borderRadius: BorderRadius.circular(
                  TioRemoveImageSheetTokens.actionRadius,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: TioRemoveImageSheetTokens.actionVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(
                      TioRemoveImageSheetTokens.actionRadius,
                    ),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(
                        TioRemoveImageSheetTokens.actionOutlineAlpha,
                      ),
                      width: TioRemoveImageSheetTokens.actionOutlineWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remove',
                        style: TextStyle(
                          color: colors.danger,
                          fontWeight: FontWeight.w700,
                          fontSize:
                              TioRemoveImageSheetTokens.actionLabelFontSize,
                        ),
                      ),
                      const SizedBox(
                        width: TioRemoveImageSheetTokens.actionIconGap,
                      ),
                      Icon(
                        Icons.delete_outline_rounded,
                        color: colors.danger,
                        size: TioRemoveImageSheetTokens.removeIconSize,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: TioRemoveImageSheetTokens.actionGap),
              InkWell(
                onTap: () => Navigator.of(sheetContext).pop(false),
                borderRadius: BorderRadius.circular(
                  TioRemoveImageSheetTokens.actionRadius,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: TioRemoveImageSheetTokens.actionVerticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(
                      TioRemoveImageSheetTokens.actionRadius,
                    ),
                    border: Border.all(
                      color: colors.outlineStrong.withAlpha(
                        TioRemoveImageSheetTokens.actionOutlineAlpha,
                      ),
                      width: TioRemoveImageSheetTokens.actionOutlineWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Cancel',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize:
                              TioRemoveImageSheetTokens.actionLabelFontSize,
                        ),
                      ),
                      const SizedBox(
                        width: TioRemoveImageSheetTokens.actionIconGap,
                      ),
                      Icon(
                        Icons.close_rounded,
                        color: colors.textPrimary,
                        size: TioRemoveImageSheetTokens.cancelIconSize,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

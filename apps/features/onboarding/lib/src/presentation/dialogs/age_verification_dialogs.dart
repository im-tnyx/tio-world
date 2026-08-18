import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

import '../theme/onboarding_age_dialog_tokens.dart';
import '../theme/onboarding_modal_tokens.dart';

class AgeVerificationDialogs {
  const AgeVerificationDialogs._();

  static const _monthAbbr = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  static String _formatDate(DateTime date) {
    final month = _monthAbbr[date.month - 1];
    return '$month ${date.day}, ${date.year}';
  }

  /// ── 1. Date Confirmation Dialog ("Is this date correct?") ──
  static Future<bool?> showConfirmation(BuildContext context, DateTime date) {
    final colors = context.tioColors;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: colors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              OnboardingAgeDialogTokens.panelRadius,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: OnboardingAgeDialogTokens.horizontalInset,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              OnboardingAgeDialogTokens.panelHorizontalPadding,
              OnboardingAgeDialogTokens.panelTopPadding,
              OnboardingAgeDialogTokens.panelHorizontalPadding,
              OnboardingAgeDialogTokens.panelBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Is this date correct?',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: OnboardingModalTokens.titleFontSize,
                    fontWeight: OnboardingModalTokens.titleFontWeight,
                  ),
                ),
                const SizedBox(height: OnboardingModalTokens.titleToBodyGap),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: OnboardingModalTokens.bodyFontSize,
                  ),
                ),
                const SizedBox(height: OnboardingModalTokens.actionTopGap),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: OnboardingAgeDialogTokens.actionHeight,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: colors.outlineStrong.withAlpha(
                                OnboardingAgeDialogTokens.outlinedActionAlpha,
                              ),
                              width:
                                  OnboardingAgeDialogTokens.outlinedActionWidth,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                OnboardingAgeDialogTokens.actionRadius,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'No',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize:
                                  OnboardingAgeDialogTokens.actionLabelFontSize,
                              fontWeight: OnboardingAgeDialogTokens
                                  .actionLabelFontWeight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: OnboardingAgeDialogTokens.choiceGap),
                    Expanded(
                      child: SizedBox(
                        height: OnboardingAgeDialogTokens.actionHeight,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: OnboardingAgeDialogTokens
                                .primaryActionBackgroundColor,
                            foregroundColor: OnboardingAgeDialogTokens
                                .primaryActionForegroundColor,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                OnboardingAgeDialogTokens.actionRadius,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: OnboardingAgeDialogTokens
                                  .primaryActionForegroundColor,
                              fontSize:
                                  OnboardingAgeDialogTokens.actionLabelFontSize,
                              fontWeight: OnboardingAgeDialogTokens
                                  .actionLabelFontWeight,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ── 2. Underage Rejection Dialog ("Sorry, we can't make your account.") ──
  static Future<void> showUnderageRejection(BuildContext context) {
    final colors = context.tioColors;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: colors.surfaceRaised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              OnboardingAgeDialogTokens.panelRadius,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: OnboardingAgeDialogTokens.horizontalInset,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              OnboardingAgeDialogTokens.panelHorizontalPadding,
              OnboardingAgeDialogTokens.panelTopPadding,
              OnboardingAgeDialogTokens.panelHorizontalPadding,
              OnboardingAgeDialogTokens.panelBottomPadding,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sorry, we can't make your account.",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: OnboardingModalTokens.titleFontSize,
                    fontWeight: OnboardingModalTokens.titleFontWeight,
                  ),
                ),
                const SizedBox(height: OnboardingModalTokens.titleToBodyGap),
                Text(
                  'Any personal information will be deleted',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: OnboardingModalTokens.bodyFontSize,
                    height: OnboardingAgeDialogTokens.rejectionBodyLineHeight,
                  ),
                ),
                const SizedBox(height: OnboardingModalTokens.actionTopGap),
                SizedBox(
                  width: double.infinity,
                  height: OnboardingAgeDialogTokens.actionHeight,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          OnboardingAgeDialogTokens.primaryActionBackgroundColor,
                      foregroundColor:
                          OnboardingAgeDialogTokens.primaryActionForegroundColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          OnboardingAgeDialogTokens.actionRadius,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Okay',
                      style: TextStyle(
                        color: OnboardingAgeDialogTokens
                            .primaryActionForegroundColor,
                        fontSize: OnboardingAgeDialogTokens.actionLabelFontSize,
                        fontWeight:
                            OnboardingAgeDialogTokens.actionLabelFontWeight,
                      ),
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
}

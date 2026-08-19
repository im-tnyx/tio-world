import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

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
            borderRadius: BorderRadius.circular(TioSize.dp20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: TioSize.dp28,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TioSpacing.xl,
              TioSpacing.xl,
              TioSpacing.xl,
              TioSize.dp20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Is this date correct?',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: TioFontSize.size18,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
                const SizedBox(height: TioSize.dp10),
                Text(
                  _formatDate(date),
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: TioFontSize.size14,
                  ),
                ),
                const SizedBox(height: TioSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: TioSize.dp48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: colors.outlineStrong.withAlpha(
                                TioAlpha.alpha90,
                              ),
                              width: TioStroke.width15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                TioSize.dp30,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text(
                            'No',
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: TioFontSize.size15,
                              fontWeight: TioFontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: TioSpacing.md),
                    Expanded(
                      child: SizedBox(
                        height: TioSize.dp48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: TioPalette.white,
                            foregroundColor: TioPalette.black,
                            elevation: TioElevation.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                TioSize.dp30,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: TioPalette.black,
                              fontSize: TioFontSize.size15,
                              fontWeight: TioFontWeight.w700,
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
            borderRadius: BorderRadius.circular(TioSize.dp20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: TioSize.dp28,
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              TioSpacing.xl,
              TioSpacing.xl,
              TioSpacing.xl,
              TioSize.dp20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Sorry, we can't make your account.",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: TioFontSize.size18,
                    fontWeight: TioFontWeight.w700,
                  ),
                ),
                const SizedBox(height: TioSize.dp10),
                Text(
                  'Any personal information will be deleted',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: TioFontSize.size14,
                    height: TioLineHeight.height130,
                  ),
                ),
                const SizedBox(height: TioSpacing.xl),
                SizedBox(
                  width: double.infinity,
                  height: TioSize.dp48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TioPalette.white,
                      foregroundColor: TioPalette.black,
                      elevation: TioElevation.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(TioSize.dp30),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Okay',
                      style: TextStyle(
                        color: TioPalette.black,
                        fontSize: TioFontSize.size15,
                        fontWeight: TioFontWeight.w700,
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

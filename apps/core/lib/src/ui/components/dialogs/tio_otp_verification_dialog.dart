import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

/// Shows the custom OTP verification popup card dialog matching the canonical design.
///
/// Can be used for Email verification, Phone OTP verification, or Password reset code.
Future<String?> showTioOtpVerificationDialog({
  required BuildContext context,
  required String targetLabel, // e.g. 'email' or 'mobile number'
  String title = 'Please enter your Code',
  String? subtitle,
  Future<bool> Function(String otp)? onVerify,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => TioOtpVerificationDialog(
      targetLabel: targetLabel,
      title: title,
      subtitle: subtitle,
      onVerify: onVerify,
    ),
  );
}

class TioOtpVerificationDialog extends StatefulWidget {
  const TioOtpVerificationDialog({
    required this.targetLabel,
    this.title = 'Please enter your Code',
    this.subtitle,
    this.onVerify,
    super.key,
  });

  final String targetLabel;
  final String title;
  final String? subtitle;
  final Future<bool> Function(String otp)? onVerify;

  @override
  State<TioOtpVerificationDialog> createState() =>
      _TioOtpVerificationDialogState();
}

class _TioOtpVerificationDialogState extends State<TioOtpVerificationDialog> {
  late TextEditingController _otpController;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _otpController.text.trim();
    if (code.length < 4) {
      setState(() => _errorMessage = 'Please enter a valid code');
      return;
    }

    if (widget.onVerify != null) {
      setState(() {
        _isVerifying = true;
        _errorMessage = null;
      });

      try {
        final success = await widget.onVerify!(code);
        if (success && mounted) {
          Navigator.of(context).pop(code);
        } else if (mounted) {
          setState(() => _errorMessage = 'Invalid code. Please try again.');
        }
      } catch (_) {
        if (mounted) {
          setState(() => _errorMessage = 'Verification failed. Try again.');
        }
      } finally {
        if (mounted) setState(() => _isVerifying = false);
      }
    } else {
      Navigator.of(context).pop(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final shadows = context.tioShadows;

    return Dialog(
      // Transparent dialog canvas lets the custom panel own its full visual.
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: TioDialogTokens.otpInsetHorizontal,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          TioSpacing.extraLarge,
          TioDialogTokens.otpPanelTopPadding,
          TioSpacing.extraLarge,
          TioSpacing.extraLarge,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(TioDialogTokens.otpPanelRadius),
          boxShadow: [
            BoxShadow(
              color: shadows.elevatedPanelColor,
              blurRadius: TioDialogTokens.otpShadowBlurRadius,
              offset: const Offset(0, TioDialogTokens.otpShadowOffsetY),
            ),
          ],
          border: Border.all(
            color: colors.outlineStrong.withAlpha(
              TioDialogTokens.otpPanelOutlineAlpha,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: TioDialogTokens.otpTitleFontSize,
                fontWeight: FontWeight.w600,
                letterSpacing: TioDialogTokens.otpTitleLetterSpacing,
              ),
            ),
            const SizedBox(height: TioDialogTokens.otpTitleToInputGap),
            Container(
              height: TioDialogTokens.otpInputHeight,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(
                  TioDialogTokens.otpInputRadius,
                ),
                border: Border.all(
                  color: _errorMessage != null
                      ? colors.danger.withAlpha(
                          TioDialogTokens.otpErrorOutlineAlpha,
                        )
                      : colors.outlineStrong.withAlpha(
                          TioDialogTokens.otpInputOutlineAlpha,
                        ),
                ),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: TioDialogTokens.otpInputHorizontalPadding,
              ),
              alignment: Alignment.center,
              child: TextField(
                controller: _otpController,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                cursorColor: colors.primary,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                onSubmitted: (_) => _handleVerify(),
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: TioDialogTokens.otpInputFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: TioDialogTokens.otpInputLetterSpacing,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  // Transparent is intentional because the capsule owns fill.
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_errorMessage case final err?) ...[
              const SizedBox(height: TioSpacing.small),
              Text(
                err,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.danger,
                  fontSize: TioDialogTokens.otpErrorFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: TioDialogTokens.otpSubtitleTopGap),
            Text(
              widget.subtitle ??
                  'Please check your ${widget.targetLabel} for the verification code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: TioDialogTokens.otpSubtitleFontSize,
                height: TioDialogTokens.otpSubtitleLineHeight,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: TioDialogTokens.otpVerifyTopGap),
            InkWell(
              onTap: _isVerifying ? null : _handleVerify,
              borderRadius: BorderRadius.circular(
                TioDialogTokens.otpActionRadius,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: TioDialogTokens.otpActionHorizontalPadding,
                  vertical: TioSpacing.medium,
                ),
                decoration: BoxDecoration(
                  color: colors.outlineStrong.withAlpha(
                    TioDialogTokens.otpActionContainerAlpha,
                  ),
                  borderRadius: BorderRadius.circular(
                    TioDialogTokens.otpActionRadius,
                  ),
                ),
                child: _isVerifying
                    ? SizedBox(
                        width: TioDialogTokens.otpLoadingSize,
                        height: TioDialogTokens.otpLoadingSize,
                        child: CircularProgressIndicator(
                          strokeWidth: TioDialogTokens.otpLoadingStrokeWidth,
                          color: colors.textPrimary,
                        ),
                      )
                    : Text(
                        'VERIFY',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: TioDialogTokens.otpActionFontSize,
                          letterSpacing:
                              TioDialogTokens.otpActionLetterSpacing,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: TioDialogTokens.otpBackTopGap),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'BACK',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: TioDialogTokens.otpActionFontSize,
                  letterSpacing: TioDialogTokens.otpActionLetterSpacing,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final colors = TioTheme.colors(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(
            color: colors.outlineStrong.withAlpha(30),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Title ──
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 18),

            // ── Dark Capsule OTP Input Box ──
            Container(
              height: 52,
              decoration: BoxDecoration(
                color: colors.background,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: _errorMessage != null
                      ? colors.danger.withAlpha(90)
                      : colors.outlineStrong.withAlpha(40),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 6,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  filled: false,
                  fillColor: Colors.transparent,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),

            if (_errorMessage case final err?) ...[
              const SizedBox(height: 8),
              Text(
                err,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.danger,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 14),

            // ── Subtitle ──
            Text(
              widget.subtitle ??
                  'Please check your ${widget.targetLabel} for the verification code.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w400,
              ),
            ),

            const SizedBox(height: 22),

            // ── VERIFY Pill Button ──
            InkWell(
              onTap: _isVerifying ? null : _handleVerify,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.outlineStrong.withAlpha(40),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: _isVerifying
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.textPrimary,
                        ),
                      )
                    : Text(
                        'VERIFY',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          letterSpacing: 0.8,
                        ),
                      ),
              ),
            ),

            const SizedBox(height: 14),

            // ── BACK Text Action ──
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Text(
                'BACK',
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

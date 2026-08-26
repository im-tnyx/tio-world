import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';
import 'package:tio_shared/shared.dart';

import '../../domain/domain.dart';

/// Shared Phone OTP form used by Signup and Login.
///
/// Code delivery is deliberately a pre-authenticated state. Only
/// [VerifyPhoneOtpUseCase] can produce [SignInSuccess].
class PhoneOtpAuthSection extends StatefulWidget {
  const PhoneOtpAuthSection({
    required this.intent,
    required this.onSignInSuccess,
    required this.onBusyChanged,
    required this.onError,
    required this.keyPrefix,
    this.requestPhoneOtpUseCase,
    this.resendPhoneOtpUseCase,
    this.verifyPhoneOtpUseCase,
    this.enabled = true,
    super.key,
  });

  final PhoneOtpIntent intent;
  final RequestPhoneOtpUseCase? requestPhoneOtpUseCase;
  final ResendPhoneOtpUseCase? resendPhoneOtpUseCase;
  final VerifyPhoneOtpUseCase? verifyPhoneOtpUseCase;
  final ValueChanged<SignInSuccess> onSignInSuccess;
  final ValueChanged<bool> onBusyChanged;
  final ValueChanged<String> onError;
  final String keyPrefix;
  final bool enabled;

  @override
  State<PhoneOtpAuthSection> createState() => _PhoneOtpAuthSectionState();
}

class _PhoneOtpAuthSectionState extends State<PhoneOtpAuthSection> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _canonicalPhone;
  bool _codeSent = false;
  bool _busy = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  bool get _canRequest {
    if (_busy || !widget.enabled) return false;
    try {
      return normalizePhoneNumberE164(_phoneController.text).isNotEmpty;
    } on ArgumentError {
      return false;
    }
  }

  bool get _canVerify =>
      !_busy &&
      widget.enabled &&
      _codeSent &&
      _otpController.text.trim().isNotEmpty;

  void _setBusy(bool value) {
    if (_busy == value) return;
    setState(() => _busy = value);
    widget.onBusyChanged(value);
  }

  void _handlePhoneChanged(String _) {
    if (_codeSent || _canonicalPhone != null) {
      setState(() {
        _codeSent = false;
        _canonicalPhone = null;
        _otpController.clear();
      });
    } else {
      setState(() {});
    }
  }

  Future<void> _requestCode() async {
    if (!_canRequest) return;
    final useCase = widget.requestPhoneOtpUseCase;
    if (useCase == null) {
      widget.onError('Phone verification is unavailable right now.');
      return;
    }

    _setBusy(true);
    try {
      final result = await useCase(
        phone: _phoneController.text,
        intent: widget.intent,
      );
      if (!mounted) return;

      switch (result) {
        case PhoneOtpCodeSent(:final canonicalPhone):
          setState(() {
            _canonicalPhone = canonicalPhone;
            _codeSent = true;
            _otpController.clear();
          });
        case PhoneOtpRequestFailure(:final message):
          widget.onError(message);
      }
    } catch (_) {
      if (mounted) {
        widget.onError('Could not send the verification code. Please try again.');
      }
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _resendCode() async {
    if (_busy || !widget.enabled || !_codeSent) return;
    final useCase = widget.resendPhoneOtpUseCase;
    if (useCase == null) {
      widget.onError('Phone verification is unavailable right now.');
      return;
    }

    _setBusy(true);
    try {
      final result = await useCase(
        phone: _canonicalPhone ?? _phoneController.text,
        intent: widget.intent,
      );
      if (!mounted) return;

      switch (result) {
        case PhoneOtpCodeSent(:final canonicalPhone):
          setState(() {
            _canonicalPhone = canonicalPhone;
            _otpController.clear();
          });
        case PhoneOtpRequestFailure(:final message):
          widget.onError(message);
      }
    } catch (_) {
      if (mounted) {
        widget.onError('Could not resend the verification code. Please try again.');
      }
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _verifyCode() async {
    if (!_canVerify) return;
    final useCase = widget.verifyPhoneOtpUseCase;
    if (useCase == null) {
      widget.onError('Phone verification is unavailable right now.');
      return;
    }

    _setBusy(true);
    try {
      final result = await useCase(
        phone: _canonicalPhone ?? _phoneController.text,
        token: _otpController.text,
      );
      if (!mounted) return;

      switch (result) {
        case SignInSuccess():
          widget.onSignInSuccess(result);
        case SignInFailure(:final message):
          widget.onError(message);
        case SignInCancelled():
          break;
      }
    } catch (_) {
      if (mounted) {
        widget.onError('Could not verify the code. Please try again.');
      }
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mobile number', style: textTheme.labelLarge),
        const SizedBox(height: TioSpacing.sm),
        TioMobileNumberField(
          fieldKey: ValueKey('${widget.keyPrefix}-phone-input'),
          controller: _phoneController,
          onChanged: _handlePhoneChanged,
          enabled: widget.enabled && !_busy && !_codeSent,
        ),
        const SizedBox(height: TioSpacing.xl),
        if (!_codeSent)
          TioButton.primary(
            key: ValueKey('${widget.keyPrefix}-phone-send-code'),
            label: 'Send Verification Code',
            expand: true,
            enabled: _canRequest,
            loading: _busy,
            onPressed: _requestCode,
          )
        else ...[
          Text(
            'Enter the verification code sent to your mobile number.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: TioSpacing.md),
          TioInput(
            key: ValueKey('${widget.keyPrefix}-phone-otp-input'),
            controller: _otpController,
            onChanged: (_) => setState(() {}),
            label: 'Verification code',
            hint: 'Enter code',
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            maxLength: 8,
            enabled: widget.enabled && !_busy,
            onSubmitted: (_) => _verifyCode(),
          ),
          const SizedBox(height: TioSpacing.lg),
          TioButton.primary(
            key: ValueKey('${widget.keyPrefix}-phone-verify-code'),
            label: 'Verify & Continue',
            expand: true,
            enabled: _canVerify,
            loading: _busy,
            onPressed: _verifyCode,
          ),
          const SizedBox(height: TioSpacing.sm),
          Align(
            alignment: Alignment.center,
            child: TextButton(
              key: ValueKey('${widget.keyPrefix}-phone-resend-code'),
              onPressed: widget.enabled && !_busy ? _resendCode : null,
              child: const Text('Resend code'),
            ),
          ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

/// Screen allowing users to optionally enter their mobile number during onboarding.
///
/// OTP verification is intentionally deferred for the current release. A mobile
/// number entered here must never be represented as verified without provider or
/// backend verification evidence.
class MobileScreen extends StatefulWidget {
  const MobileScreen({
    super.key,
    required this.initialMobile,
    required this.isVerified,
    required this.onMobileChanged,
    required this.onVerificationCompleted,
  });

  final String initialMobile;
  final bool isVerified;
  final ValueChanged<String> onMobileChanged;
  final ValueChanged<bool> onVerificationCompleted;

  @override
  State<MobileScreen> createState() => _MobileScreenState();
}

class _MobileScreenState extends State<MobileScreen> {
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(
      text: _nationalPhoneDigits(widget.initialMobile),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String value) {
    // Editing the number invalidates any previously verified profile-mobile
    // evidence. Current onboarding does not perform OTP verification itself.
    widget.onVerificationCompleted(false);
    final trimmed = value.trim();
    widget.onMobileChanged(trimmed.isEmpty ? '' : '+91 $trimmed');
  }

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TioScreenHeader(
          title: "What's your mobile number?",
          subtitle:
              'Add a mobile number for account recovery and future security options. This step is optional and can be completed later.',
        ),
        const SizedBox(height: TioSpacing.large),
        TioMobileNumberField(
          fieldKey: const ValueKey('mobile-number-input'),
          controller: _phoneController,
          isVerified: widget.isVerified,
          onChanged: _onPhoneChanged,
          hintText: 'Enter 10-digit number',
        ),
        const SizedBox(height: TioSpacing.small),
        Text(
          widget.isVerified
              ? 'Verified by your authentication provider.'
              : 'You can add or verify a mobile number later from Account Settings.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: 12,
            height: 1.3,
          ),
        ),
      ],
    );
  }
}

String _nationalPhoneDigits(String value) {
  final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.startsWith('91') && digits.length > 10) {
    return digits.substring(2);
  }
  if (digits.length > 10) {
    return digits.substring(digits.length - 10);
  }
  return digits;
}

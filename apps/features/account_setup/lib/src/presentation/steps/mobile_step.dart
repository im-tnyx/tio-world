import 'package:flutter/material.dart';
import 'package:tio_core/core.dart';

class MobileStep extends StatefulWidget {
  const MobileStep({
    required this.initialMobile,
    required this.isVerified,
    required this.enabled,
    required this.onChanged,
    super.key,
  });

  final String initialMobile;
  final bool isVerified;
  final bool enabled;
  final ValueChanged<String> onChanged;

  @override
  State<MobileStep> createState() => _MobileStepState();
}

class _MobileStepState extends State<MobileStep> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: _nationalPhoneDigits(widget.initialMobile),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChanged(String value) {
    final trimmed = value.trim();
    widget.onChanged(trimmed.isEmpty ? '' : '+91 $trimmed');
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TioScreenHeader(
          title: "What's your mobile number?",
          subtitle:
              'Add a mobile number for account recovery and future security options. This step is optional and can be completed later.',
        ),
        const SizedBox(height: TioSpacing.lg),
        TioMobileNumberField(
          fieldKey: const ValueKey('account-setup-mobile-input'),
          controller: _controller,
          enabled: widget.enabled,
          isVerified: widget.isVerified,
          onChanged: _handleChanged,
          hintText: 'Enter 10-digit number',
        ),
        const SizedBox(height: TioSpacing.sm),
        Text(
          widget.isVerified
              ? 'Verified by your authentication provider.'
              : 'You can add or verify a mobile number later from Account Settings.',
          style: TextStyle(
            color: colors.textMuted,
            fontSize: TioFontSize.size12,
            height: TioLineHeight.height130,
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

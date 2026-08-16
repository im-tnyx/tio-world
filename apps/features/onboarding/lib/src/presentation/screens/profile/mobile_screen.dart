import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tio_core/core.dart';

/// Screen allowing users to optionally enter and verify their mobile number during onboarding.
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
  bool _isAgreed = true;
  bool _isLocallyVerified = false;

  @override
  void initState() {
    super.initState();
    final raw = widget.initialMobile.replaceAll(RegExp(r'[^\d]'), '');
    final national = raw.startsWith('91') && raw.length > 10
        ? raw.substring(2)
        : raw;
    _phoneController = TextEditingController(text: national);
    _isLocallyVerified = widget.isVerified;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isVerified => _isLocallyVerified || widget.isVerified;

  bool get _isValid => _phoneController.text.trim().length == 10;

  void _onPhoneChanged(String val) {
    setState(() {
      _isLocallyVerified = false;
      if (val.length == 10) {
        _isAgreed = true;
      }
    });
    widget.onVerificationCompleted(false);
    final formatted = val.trim().isEmpty ? '' : '+91 ${val.trim()}';
    widget.onMobileChanged(formatted);
  }

  Future<void> _handleVerify() async {
    final number = _phoneController.text.trim();
    if (number.length != 10) return;

    final code = await showTioOtpVerificationDialog(
      context: context,
      targetLabel: 'mobile (+91 $number)',
      title: 'Enter Verification Code',
      subtitle: 'Please check your mobile for the 4-digit verification code.',
    );

    if (code != null && mounted) {
      setState(() {
        _isLocallyVerified = true;
      });
      widget.onVerificationCompleted(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number verified successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfoSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final colors = sheetContext.tioColors;
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TioRadius.large),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(
            TioSpacing.large,
            TioSpacing.large,
            TioSpacing.large,
            TioSpacing.extraLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: TioSpacing.medium),
              Text(
                'Data Collection & Privacy',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: TioSpacing.small),
              Text(
                'Your phone number is used exclusively for account recovery, multi-factor security, and optional workout reminders. We never share or sell your contact information to third parties.',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: TioSpacing.large),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: colors.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(TioRadius.medium),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: const Text(
                    'Understood',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: TioSpacing.large),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: TioSpacing.small),
          Text(
            "What's your mobile number?",
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: TioSpacing.small),
          Text(
            'Link your phone number to secure your account and sync your coaching progress across devices.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TioSpacing.extraLarge),

          // Phone input card container
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(TioRadius.medium),
              border: Border.all(
                color: _isVerified
                    ? const Color(0xFF1DA1F2).withAlpha(120)
                    : colors.surfaceVariant,
                width: _isVerified ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.medium,
              vertical: TioSpacing.small,
            ),
            child: Row(
              children: [
                // Country Code Prefix Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🇮🇳',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '+91',
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: TioSpacing.medium),

                // National Phone Number Input
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    onChanged: _onPhoneChanged,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter 10-digit number',
                      hintStyle: TextStyle(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),

                // Verify Button / Verified Status Icon
                if (_isVerified) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1DA1F2).withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 18,
                          color: Color(0xFF1DA1F2),
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Verified',
                          style: TextStyle(
                            color: Color(0xFF1DA1F2),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_isValid) ...[
                  GestureDetector(
                    onTap: _handleVerify,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Verify',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: TioSpacing.medium),

          // Agreement Checkbox
          InkWell(
            onTap: () {
              setState(() => _isAgreed = !_isAgreed);
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _isAgreed,
                      onChanged: (val) {
                        setState(() => _isAgreed = val ?? false);
                      },
                      activeColor: colors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'I agree to receive workout updates & goal reminders via SMS/WhatsApp',
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: TioSpacing.extraLarge),

          // Info Link
          Center(
            child: GestureDetector(
              onTap: _showInfoSheet,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: colors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Why do we ask for your mobile number?',
                    style: TextStyle(
                      color: colors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: TioSpacing.large),
        ],
      ),
    );
  }
}

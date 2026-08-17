import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    final raw = widget.initialMobile.replaceAll(RegExp(r'[^\d]'), '');
    final national = raw.startsWith('91') && raw.length > 10
        ? raw.substring(2)
        : raw;
    _phoneController = TextEditingController(text: national);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneChanged(String val) {
    // Editing the number invalidates any previously verified profile-mobile
    // evidence. Current onboarding does not perform OTP verification itself.
    widget.onVerificationCompleted(false);
    final formatted = val.trim().isEmpty ? '' : '+91 ${val.trim()}';
    widget.onMobileChanged(formatted);
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
            "What's your mobile number? (Optional)",
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: TioSpacing.small),
          Text(
            'Add your mobile number for account recovery and future security options, or leave it blank and continue.',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: TioSpacing.extraLarge),
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(TioRadius.medium),
              border: Border.all(
                color: widget.isVerified
                    ? const Color(0xFF1DA1F2).withAlpha(120)
                    : colors.surfaceVariant,
                width: widget.isVerified ? 1.5 : 1.0,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: TioSpacing.medium,
              vertical: TioSpacing.small,
            ),
            child: Row(
              children: [
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
                Expanded(
                  child: TextField(
                    key: const ValueKey('mobile-number-input'),
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
                if (widget.isVerified)
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
              ],
            ),
          ),
          const SizedBox(height: TioSpacing.small),
          Text(
            widget.isVerified
                ? 'Verified by your authentication provider.'
                : 'Verification is optional for now and can be completed later.',
            style: TextStyle(
              color: colors.textMuted,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: TioSpacing.extraLarge),
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

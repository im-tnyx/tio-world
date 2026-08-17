import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

/// Shared mobile-number input used by onboarding/account setup and Settings.
///
/// This widget owns presentation only. Verification remains caller-owned: a
/// Verify action is shown only when [onVerifyPressed] is supplied, and a
/// verified badge is rendered only from trusted [isVerified] state.
class TioMobileNumberField extends StatelessWidget {
  const TioMobileNumberField({
    required this.controller,
    required this.onChanged,
    super.key,
    this.fieldKey,
    this.isVerified = false,
    this.onVerifyPressed,
    this.enabled = true,
    this.countryFlag = '🇮🇳',
    this.countryCode = '+91',
    this.hintText = 'Enter mobile number',
    this.maxDigits = 10,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final Key? fieldKey;
  final bool isVerified;
  final VoidCallback? onVerifyPressed;
  final bool enabled;
  final String countryFlag;
  final String countryCode;
  final String hintText;
  final int maxDigits;

  @override
  Widget build(BuildContext context) {
    final colors = TioTheme.colors(context);

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final hasNumber = value.text.trim().isNotEmpty;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Semantics(
              label: '$countryFlag $countryCode',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(countryFlag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: TioSpacing.small),
                  Text(
                    countryCode,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TioSpacing.medium + 2),
            Expanded(
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(TioRadius.large),
                  border: Border.all(
                    color: isVerified
                        ? colors.info.withValues(alpha: 0.45)
                        : colors.outlineStrong.withValues(alpha: 0.16),
                    width: isVerified ? 1.5 : 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: TioSpacing.large),
                alignment: Alignment.center,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: fieldKey,
                        controller: controller,
                        enabled: enabled,
                        keyboardType: TextInputType.phone,
                        cursorColor: colors.primary,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(maxDigits),
                        ],
                        onChanged: onChanged,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.5,
                        ),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          filled: false,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          hintText: hintText,
                          hintStyle: TextStyle(
                            color: colors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    if (isVerified)
                      Semantics(
                        label: 'Verified mobile number',
                        child: Icon(
                          Icons.verified_rounded,
                          size: 22,
                          color: colors.info,
                        ),
                      )
                    else if (hasNumber && onVerifyPressed != null)
                      Semantics(
                        button: true,
                        label: 'Verify mobile number',
                        child: InkWell(
                          onTap: enabled ? onVerifyPressed : null,
                          borderRadius: BorderRadius.circular(TioRadius.small),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
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
                      ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

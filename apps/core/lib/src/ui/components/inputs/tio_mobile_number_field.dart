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
    final colors = context.tioColors;

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
                  Text(
                    countryFlag,
                    style: const TextStyle(
                      fontSize: TioInputTokens.mobileCountryFlagFontSize,
                    ),
                  ),
                  const SizedBox(width: TioSpacing.sm),
                  Text(
                    countryCode,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: TioInputTokens.mobileCountryCodeFontSize,
                      fontWeight: TioFontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: TioInputTokens.mobileCountryToFieldGap),
            Expanded(
              child: Container(
                height: TioInputTokens.mobileFieldHeight,
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: BorderRadius.circular(TioRadius.lg),
                  border: Border.all(
                    color: isVerified
                        ? colors.info.withValues(
                            alpha: TioInputTokens.mobileVerifiedOutlineOpacity,
                          )
                        : colors.outlineStrong.withValues(
                            alpha: TioInputTokens.mobileDefaultOutlineOpacity,
                          ),
                    width: isVerified
                        ? TioInputTokens.mobileVerifiedOutlineWidth
                        : TioInputTokens.mobileDefaultOutlineWidth,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: TioInputTokens.horizontalPadding,
                ),
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
                          fontSize: TioInputTokens.mobileTextFontSize,
                          fontWeight: TioFontWeight.w500,
                          letterSpacing: TioInputTokens.mobileTextLetterSpacing,
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
                            fontWeight: TioFontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    if (isVerified)
                      Semantics(
                        label: 'Verified mobile number',
                        child: Icon(
                          Icons.verified_rounded,
                          size: TioInputTokens.mobileVerifiedIconSize,
                          color: colors.info,
                        ),
                      )
                    else if (hasNumber && onVerifyPressed != null)
                      Semantics(
                        button: true,
                        label: 'Verify mobile number',
                        child: InkWell(
                          onTap: enabled ? onVerifyPressed : null,
                          borderRadius: BorderRadius.circular(TioRadius.sm),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal:
                                  TioInputTokens.mobileVerifyHorizontalPadding,
                              vertical: TioInputTokens.mobileVerifyVerticalPadding,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary.withValues(
                                alpha:
                                    TioInputTokens.mobileVerifyContainerOpacity,
                              ),
                              borderRadius: BorderRadius.circular(
                                TioRadius.sm,
                              ),
                            ),
                            child: Text(
                              'Verify',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: TioFontWeight.w700,
                                fontSize:
                                    TioInputTokens.mobileVerifyLabelFontSize,
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

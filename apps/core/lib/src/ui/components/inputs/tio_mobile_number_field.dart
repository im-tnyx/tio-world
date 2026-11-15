import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

/// Shared mobile-number input used by onboarding/account setup and Settings.
///
/// This widget owns presentation only. Verification remains caller-owned: a
/// Verify action is shown only when [onVerifyPressed] is supplied, and a
/// verified badge is rendered only from trusted [isVerified] state.
class TioMobileNumberField extends StatefulWidget {
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
  State<TioMobileNumberField> createState() => _TioMobileNumberFieldState();
}

class _TioMobileNumberFieldState extends State<TioMobileNumberField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final isFocused =
        widget.enabled && !widget.isVerified && _focusNode.hasFocus;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.controller,
      builder: (context, value, _) {
        final hasNumber = value.text.trim().isNotEmpty;

        return Container(
          height: TioInputTokens.mobileFieldHeight,
          decoration: BoxDecoration(
            color: colors.surfaceRaised,
            borderRadius: BorderRadius.circular(TioRadius.lg),
            border: Border.all(
              color: widget.isVerified
                  ? colors.info.withValues(
                      alpha: TioInputTokens.mobileVerifiedOutlineOpacity,
                    )
                  : isFocused
                      ? colors.primary
                      : colors.outlineStrong.withValues(
                          alpha: TioInputTokens.mobileDefaultOutlineOpacity,
                        ),
              width: widget.isVerified
                  ? TioInputTokens.mobileVerifiedOutlineWidth
                  : isFocused
                      ? TioInputTokens.focusedOutlineWidth
                      : TioInputTokens.mobileDefaultOutlineWidth,
            ),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: TioInputTokens.horizontalPadding,
          ),
          alignment: Alignment.center,
          child: Row(
            children: [
              Semantics(
                label: '${widget.countryFlag} ${widget.countryCode}',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.countryFlag,
                      style: const TextStyle(
                        fontSize: TioInputTokens.mobileCountryFlagFontSize,
                      ),
                    ),
                    const SizedBox(width: TioSpacing.sm),
                    Text(
                      widget.countryCode,
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
                child: TextField(
                  key: widget.fieldKey,
                  controller: widget.controller,
                  focusNode: _focusNode,
                  enabled: widget.enabled,
                  keyboardType: TextInputType.phone,
                  cursorColor: colors.primary,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.maxDigits),
                  ],
                  onChanged: widget.onChanged,
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
                    hintText: widget.hintText,
                    hintStyle: TextStyle(
                      color: colors.textMuted,
                      fontWeight: TioFontWeight.w400,
                    ),
                  ),
                ),
              ),
              if (widget.isVerified)
                Semantics(
                  label: 'Verified mobile number',
                  child: Icon(
                    Icons.verified_rounded,
                    size: TioInputTokens.mobileVerifiedIconSize,
                    color: colors.info,
                  ),
                )
              else if (hasNumber && widget.onVerifyPressed != null)
                Semantics(
                  button: true,
                  label: 'Verify mobile number',
                  child: InkWell(
                    onTap: widget.enabled ? widget.onVerifyPressed : null,
                    borderRadius: BorderRadius.circular(TioRadius.sm),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal:
                            TioInputTokens.mobileVerifyHorizontalPadding,
                        vertical: TioInputTokens.mobileVerifyVerticalPadding,
                      ),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(
                          alpha: TioInputTokens.mobileVerifyContainerOpacity,
                        ),
                        borderRadius: BorderRadius.circular(TioRadius.sm),
                      ),
                      child: Text(
                        'Verify',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: TioFontWeight.w700,
                          fontSize: TioInputTokens.mobileVerifyLabelFontSize,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

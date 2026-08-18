import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

/// Available visual variants for [TioInput].
enum TioInputVariant {
  /// Standard full-width outlined input for forms, auth, and search.
  standard,

  /// Compact, high-visibility number field for workout sets/reps, weights, and timers.
  compactNumber,
}

/// Reusable input field adhering to AGENTS.md and Material 3 design tokens.
///
/// Supports:
/// - [TioInputVariant.standard] for general form entries.
/// - [TioInputVariant.compactNumber] for fast table inputs with `selectAllOnFocus`.
class TioInput extends StatefulWidget {
  const TioInput({
    required this.onChanged,
    this.value,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.textStyle,
    this.contentPadding,
    this.selectAllOnFocus = false,
    this.variant = TioInputVariant.standard,
    super.key,
  });

  /// Specialized compact constructor for numerical inputs in sets/reps tables.
  const TioInput.compactNumber({
    required this.onChanged,
    this.value,
    this.controller,
    this.label,
    this.hint,
    this.helperText,
    this.errorText,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.textAlign = TextAlign.center,
    this.textStyle,
    this.contentPadding,
    this.selectAllOnFocus = true,
    super.key,
  }) : variant = TioInputVariant.compactNumber;

  final String? value;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final String? label;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final Widget? leading;
  final Widget? trailing;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? contentPadding;
  final bool selectAllOnFocus;
  final TioInputVariant variant;

  @override
  State<TioInput> createState() => _TioInputState();
}

class _TioInputState extends State<TioInput> {
  late FocusNode _focusNode;
  late TextEditingController _controller;
  bool _ownsController = false;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _controller = widget.controller ?? TextEditingController(text: widget.value ?? '');
    _ownsController = widget.controller == null;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant TioInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) _controller.dispose();
      _controller = widget.controller ?? TextEditingController(text: widget.value ?? '');
      _ownsController = widget.controller == null;
    } else if (_ownsController && widget.value != null && widget.value != oldWidget.value) {
      if (_controller.text != widget.value) {
        _controller.value = TextEditingValue(
          text: widget.value!,
          selection: TextSelection.collapsed(offset: widget.value!.length),
        );
      }
    }
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_handleFocusChange);
    }
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });

    if (_focusNode.hasFocus && widget.selectAllOnFocus && _controller.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_focusNode.hasFocus) return;
        _controller.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _controller.text.length,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.tioColors;
    final textTheme = Theme.of(context).textTheme;
    final isCompact = widget.variant == TioInputVariant.compactNumber;
    final isDark = colors.isDark;
    final hasError = widget.errorText != null;

    final defaultTextStyle = isCompact
        ? TextStyle(
            color: hasError
                ? colors.danger
                : (widget.enabled ? colors.textPrimary : colors.textMuted),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          )
        : textTheme.bodyLarge?.copyWith(
            color: hasError ? colors.danger : colors.textPrimary,
          );

    final inputBorderRadius = BorderRadius.circular(TioInputTokens.radius);
    final unfocusedBorderColor = colors.outlineStrong.withValues(alpha: isDark ? 0.35 : 0.45);
    final focusedBorderColor = colors.primary;

    final effectiveBorder = isCompact
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(
              color: hasError ? colors.danger : unfocusedBorderColor,
              width: TioCardTokens.borderThin, // 0.75px (AppDimens.borderThin)
            ),
          );

    final effectiveFocusedBorder = isCompact
        ? UnderlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? colors.danger : colors.primary,
              width: TioCardTokens.borderThick, // 1.25px (AppDimens.borderThick)
            ),
          )
        : OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(
              color: hasError ? colors.danger : focusedBorderColor,
              width: TioCardTokens.borderThick, // 1.25px (AppDimens.borderThick)
            ),
          );

    return TextFormField(
      controller: _controller,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType ??
          (isCompact ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text),
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      textAlign: widget.textAlign,
      textAlignVertical: isCompact ? TextAlignVertical.center : null,
      style: widget.textStyle ?? defaultTextStyle,
      cursorColor: hasError ? colors.danger : colors.primary,
      decoration: InputDecoration(
        labelText: isCompact ? null : widget.label,
        hintText: widget.hint,
        helperText: hasError ? null : widget.helperText,
        errorText: widget.errorText,
        prefixIcon: widget.leading,
        suffixIcon: widget.trailing,
        counterText: isCompact ? '' : null,
        filled: !isCompact,
        fillColor: colors.surface,
        labelStyle: TextStyle(
          color: hasError
              ? colors.danger
              : (_isFocused ? colors.textPrimary : colors.textSecondary),
          fontSize: 14,
        ),
        floatingLabelStyle: TextStyle(
          color: hasError ? colors.danger : colors.textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: colors.textMuted,
          fontSize: isCompact ? 15 : 14,
          fontWeight: isCompact ? FontWeight.w600 : FontWeight.normal,
        ),
        enabledBorder: effectiveBorder,
        focusedBorder: effectiveFocusedBorder,
        errorBorder: effectiveBorder,
        focusedErrorBorder: effectiveFocusedBorder,
        contentPadding: widget.contentPadding ??
            (isCompact
                ? const EdgeInsets.symmetric(vertical: 10, horizontal: 8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 16)),
      ),
    );
  }
}

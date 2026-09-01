import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../theme/theme.dart';

/// Available visual variants for [TioInput].
enum TioInputVariant {
  /// Standard full-width outlined input for forms, auth, and search.
  standard,

  /// Compact, high-visibility number field for workout sets/reps, weights, and timers.
  compactNumber,

  /// Dense, left-aligned number field for exact-value editor surfaces.
  numericEditor,
}

/// Reusable input field adhering to AGENTS.md and Material 3 design tokens.
///
/// Supports:
/// - [TioInputVariant.standard] for general form entries.
/// - [TioInputVariant.compactNumber] for fast table inputs with `selectAllOnFocus`.
/// - [TioInputVariant.numericEditor] for dense exact-value editor surfaces.
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
    this.validator,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.suffixText,
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
    this.validator,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.suffixText,
    super.key,
  }) : variant = TioInputVariant.compactNumber;

  /// Dense numeric field for exact-value editor surfaces.
  ///
  /// Unlike [TioInput.compactNumber], this variant remains left-aligned, does
  /// not select all on focus, and retains the dense [InputDecoration] defaults
  /// used by exact-value editors. The active input-decoration theme continues
  /// to supply fill, border, radius, and padding. Callers continue to own the
  /// numeric formatter, unit text, validation, and submit behavior.
  const TioInput.numericEditor({
    required this.onChanged,
    this.value,
    this.controller,
    this.hint,
    this.helperText,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.textInputAction = TextInputAction.done,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textStyle,
    this.contentPadding,
    this.validator,
    this.autofillHints,
    this.inputFormatters,
    this.textCapitalization = TextCapitalization.none,
    this.suffixText,
    super.key,
  })  : label = null,
        leading = null,
        trailing = null,
        obscureText = false,
        maxLines = 1,
        minLines = null,
        maxLength = null,
        textAlign = TextAlign.start,
        selectAllOnFocus = false,
        variant = TioInputVariant.numericEditor;

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

  /// Form validation callback, forwarded to the underlying [TextFormField].
  ///
  /// Plumbing only: this component owns no validation rule. Exposing the
  /// callback introduces no validation timing of its own — with no
  /// `autovalidateMode`, the field validates only when an enclosing [Form]
  /// asks it to, exactly as before.
  ///
  /// One asymmetry worth knowing before relying on it: a validator error
  /// renders its message through the decoration, but [errorText] is what
  /// drives this component's error *styling* (border, cursor, label colour).
  /// A validator-only error therefore shows the message without the error
  /// colours. Unifying the two would mean reading `FormFieldState` inside the
  /// build, which is a larger change than this additive API; the first
  /// consumer that needs both should carry it.
  final String? Function(String?)? validator;

  /// Autofill hints forwarded to the platform, e.g. `[AutofillHints.email]`.
  ///
  /// Features choose the hints; core does not infer them from the label or
  /// keyboard type.
  final Iterable<String>? autofillHints;

  /// Input formatters forwarded to the underlying field.
  ///
  /// Plumbing only. Core adds no formatter of its own — no numeric rule, no
  /// decimal policy, no normalisation, no unit handling. The consumer owns
  /// the list.
  final List<TextInputFormatter>? inputFormatters;

  /// Capitalisation behaviour. Defaults to [TextCapitalization.none], which
  /// is the behaviour every existing consumer already gets.
  final TextCapitalization textCapitalization;

  /// Static text shown after the input, such as a unit. Presentation plumbing
  /// only: core attaches no unit or domain meaning to it.
  ///
  /// No matching prefix parameter is exposed: no editable-field consumer needs
  /// one today, and this component does not ship API ahead of evidence.
  final String? suffixText;

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
    _controller =
        widget.controller ?? TextEditingController(text: widget.value ?? '');
    _ownsController = widget.controller == null;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant TioInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (_ownsController) _controller.dispose();
      _controller =
          widget.controller ?? TextEditingController(text: widget.value ?? '');
      _ownsController = widget.controller == null;
    } else if (_ownsController &&
        widget.value != null &&
        widget.value != oldWidget.value) {
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

    if (_focusNode.hasFocus &&
        widget.selectAllOnFocus &&
        _controller.text.isNotEmpty) {
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
    final isNumericEditor = widget.variant == TioInputVariant.numericEditor;
    final isDark = colors.isDark;
    final hasError = widget.errorText != null;

    final defaultTextStyle = switch (widget.variant) {
      TioInputVariant.compactNumber => TextStyle(
          color: hasError
              ? colors.danger
              : (widget.enabled ? colors.textPrimary : colors.textMuted),
          fontSize: TioInputTokens.compactTextFontSize,
          fontWeight: TioFontWeight.w700,
        ),
      TioInputVariant.numericEditor => TextStyle(
          color: colors.textPrimary,
          fontSize: TioInputTokens.numericEditorTextFontSize,
          fontWeight: TioFontWeight.w700,
        ),
      TioInputVariant.standard => textTheme.bodyLarge?.copyWith(
          color: hasError ? colors.danger : colors.textPrimary,
        ),
    };

    final inputBorderRadius = BorderRadius.circular(TioInputTokens.radius);
    final unfocusedBorderColor = colors.outlineStrong.withValues(
      alpha: isDark
          ? TioInputTokens.darkUnfocusedOutlineOpacity
          : TioInputTokens.lightUnfocusedOutlineOpacity,
    );
    final focusedBorderColor = colors.primary;

    final effectiveBorder = isCompact
        ? InputBorder.none
        : OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(
              color: hasError ? colors.danger : unfocusedBorderColor,
              width: TioInputTokens.outlineWidth,
            ),
          );

    final effectiveFocusedBorder = isCompact
        ? UnderlineInputBorder(
            borderSide: BorderSide(
              color: hasError ? colors.danger : colors.primary,
              width: TioInputTokens.focusedOutlineWidth,
            ),
          )
        : OutlineInputBorder(
            borderRadius: inputBorderRadius,
            borderSide: BorderSide(
              color: hasError ? colors.danger : focusedBorderColor,
              width: TioInputTokens.focusedOutlineWidth,
            ),
          );

    return TextFormField(
      controller: _controller,
      onChanged: widget.onChanged,
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      keyboardType: widget.keyboardType ??
          (isCompact || isNumericEditor
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text),
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      textCapitalization: widget.textCapitalization,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      maxLines: widget.obscureText ? 1 : widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      textAlign: widget.textAlign,
      textAlignVertical: isCompact ? TextAlignVertical.center : null,
      style: widget.textStyle ?? defaultTextStyle,
      cursorColor: hasError ? colors.danger : colors.primary,
      decoration: isNumericEditor
          ? InputDecoration(
              isDense: true,
              hintText: widget.hint,
              helperText: hasError ? null : widget.helperText,
              errorText: widget.errorText,
              suffixText: widget.suffixText,
              suffixStyle: TextStyle(
                color: colors.textSecondary,
                fontSize: TioInputTokens.numericEditorSuffixFontSize,
              ),
              hintStyle: TextStyle(
                color: colors.textMuted,
                fontSize: TioInputTokens.numericEditorHintFontSize,
                fontWeight: TioFontWeight.w400,
              ),
              // Null preserves the active theme's existing dense padding.
              contentPadding: widget.contentPadding,
            )
          : InputDecoration(
              labelText: isCompact ? null : widget.label,
              hintText: widget.hint,
              helperText: hasError ? null : widget.helperText,
              errorText: widget.errorText,
              prefixIcon: widget.leading,
              suffixIcon: widget.trailing,
              // Null unless a consumer opts in, so no field gains a suffix by
              // default and nothing currently rendered changes.
              suffixText: widget.suffixText,
              counterText: isCompact ? '' : null,
              filled: !isCompact,
              fillColor: colors.surface,
              labelStyle: TextStyle(
                color: hasError
                    ? colors.danger
                    : (_isFocused ? colors.textPrimary : colors.textSecondary),
                fontSize: TioInputTokens.labelFontSize,
              ),
              floatingLabelStyle: TextStyle(
                color: hasError ? colors.danger : colors.textPrimary,
                fontSize: TioInputTokens.labelFontSize,
                fontWeight: TioFontWeight.w500,
              ),
              hintStyle: TextStyle(
                color: colors.textMuted,
                fontSize: isCompact
                    ? TioInputTokens.compactHintFontSize
                    : TioInputTokens.standardHintFontSize,
                fontWeight: isCompact ? TioFontWeight.w600 : TioFontWeight.w400,
              ),
              enabledBorder: effectiveBorder,
              focusedBorder: effectiveFocusedBorder,
              errorBorder: effectiveBorder,
              focusedErrorBorder: effectiveFocusedBorder,
              contentPadding: widget.contentPadding ??
                  (isCompact
                      ? const EdgeInsets.symmetric(
                          vertical:
                              TioInputTokens.compactContentVerticalPadding,
                          horizontal:
                              TioInputTokens.compactContentHorizontalPadding,
                        )
                      : const EdgeInsets.symmetric(
                          horizontal: TioInputTokens.horizontalPadding,
                          vertical:
                              TioInputTokens.standardContentVerticalPadding,
                        )),
            ),
    );
  }
}

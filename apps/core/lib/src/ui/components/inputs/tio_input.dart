import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class TioInput extends StatelessWidget {
  const TioInput({
    required this.value,
    required this.onChanged,
    super.key,
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
    this.textInputAction,
    this.maxLines = 1,
  });

  final String value;
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
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      enabled: enabled,
      readOnly: readOnly,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: obscureText ? 1 : maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: errorText == null ? helperText : null,
        errorText: errorText,
        prefixIcon: leading,
        suffixIcon: trailing,
        contentPadding: EdgeInsets.all(TioTheme.spacing.medium),
      ),
    );
  }
}

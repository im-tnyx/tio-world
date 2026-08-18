import 'package:flutter/material.dart';

import 'auth_form_tokens.dart';

/// Login-only visual contracts that intentionally differ from reusable core
/// Input defaults or from the Sign Up surface.
class AuthLoginTokens {
  const AuthLoginTokens._();

  // Temporary surface alias while Login migrates directly to the shared role.
  static const backIconSize = AuthFormTokens.backIconSize;

  static const inputEnabledOutlineWidth = 1.2;
  static const inputFocusedOutlineWidth = 1.8;
  static const inputFloatingLabelFontWeight = FontWeight.w500;

  static const dividerThickness = 1.0;
  static const dividerLabelFontSize = 11.0;
  static const dividerLabelFontWeight = FontWeight.w600;
  static const dividerLabelLetterSpacing = 0.5;
}

import 'auth_form_tokens.dart';

/// Sign Up-only visual contracts that intentionally differ from reusable core
/// Input defaults or from the other Auth form surfaces.
class AuthSignupTokens {
  const AuthSignupTokens._();

  // Temporary surface aliases while the Sign Up screen migrates directly to
  // the promoted shared Auth form roles. Values remain single-source.
  static const inputPrefixIconSize = AuthFormTokens.inputLeadingIconSize;
  static const dividerLabelLetterSpacing =
      AuthFormTokens.dividerLabelLetterSpacing;

  static const inputHintOpacity = 0.60;
  static const inputContentVerticalPadding = 14.0;
  static const inputOutlineOpacity = 0.40;
  static const inputFocusedOutlineWidth = 2.0;

  static const submitTopGap = 28.0;
}

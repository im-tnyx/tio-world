import 'auth_form_tokens.dart';

/// Email Login-only visual contracts that are not shared by the canonical
/// Auth form chrome or reusable core Input components.
class AuthEmailLoginTokens {
  const AuthEmailLoginTokens._();

  static const passwordVisibilityIconSize = 20.0;

  // Temporary surface alias while Email Login migrates directly to the shared
  // secondary Auth action role.
  static const forgotPasswordFontWeight =
      AuthFormTokens.secondaryActionFontWeight;

  static const postSubmitGap = 28.0;
}

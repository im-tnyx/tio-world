import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/presentation/theme/auth_forgot_password_tokens.dart';

void main() {
  group('Auth Forgot Password visual contracts', () {
    test('keeps reset-form spacing', () {
      expect(AuthForgotPasswordTokens.titleToDescriptionGap, 6.0);
      expect(AuthForgotPasswordTokens.descriptionToInputGap, 40.0);
      expect(AuthForgotPasswordTokens.submitTopGap, 28.0);
    });

    test('keeps success-state presentation', () {
      expect(AuthForgotPasswordTokens.successTopGap, 48.0);
      expect(AuthForgotPasswordTokens.successIconContainerSize, 80.0);
      expect(AuthForgotPasswordTokens.successIconContainerOpacity, 0.12);
      expect(AuthForgotPasswordTokens.successIconSize, 40.0);
      expect(AuthForgotPasswordTokens.successIconToTitleGap, 28.0);
      expect(AuthForgotPasswordTokens.successTitleToBodyGap, 10.0);
      expect(AuthForgotPasswordTokens.successBodyToButtonGap, 40.0);
    });
  });
}

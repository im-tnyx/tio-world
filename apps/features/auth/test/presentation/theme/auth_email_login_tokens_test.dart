import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/presentation/theme/auth_email_login_tokens.dart';

void main() {
  group('Auth Email Login visual contracts', () {
    test('keeps audited action and icon treatment', () {
      expect(AuthEmailLoginTokens.passwordVisibilityIconSize, 20.0);
      expect(
        AuthEmailLoginTokens.forgotPasswordFontWeight,
        FontWeight.w600,
      );
      expect(AuthEmailLoginTokens.postSubmitGap, 28.0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/presentation/theme/auth_login_tokens.dart';

void main() {
  group('Auth Login visual contracts', () {
    test('keeps audited input chrome values', () {
      expect(AuthLoginTokens.backIconSize, 24.0);
      expect(AuthLoginTokens.inputEnabledOutlineWidth, 1.2);
      expect(AuthLoginTokens.inputFocusedOutlineWidth, 1.8);
      expect(AuthLoginTokens.inputFloatingLabelFontWeight, FontWeight.w500);
    });

    test('keeps audited divider treatment', () {
      expect(AuthLoginTokens.dividerThickness, 1.0);
      expect(AuthLoginTokens.dividerLabelFontSize, 11.0);
      expect(AuthLoginTokens.dividerLabelFontWeight, FontWeight.w600);
      expect(AuthLoginTokens.dividerLabelLetterSpacing, 0.5);
    });
  });
}

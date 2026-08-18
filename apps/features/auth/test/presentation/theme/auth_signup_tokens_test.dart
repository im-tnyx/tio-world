import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/src/presentation/theme/auth_signup_tokens.dart';

void main() {
  group('Auth Sign Up visual contracts', () {
    test('keeps audited input presentation', () {
      expect(AuthSignupTokens.inputHintOpacity, 0.60);
      expect(AuthSignupTokens.inputContentVerticalPadding, 14.0);
      expect(AuthSignupTokens.inputOutlineOpacity, 0.40);
      expect(AuthSignupTokens.inputFocusedOutlineWidth, 2.0);
    });

    test('keeps audited action spacing', () {
      expect(AuthSignupTokens.submitTopGap, 28.0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/src/presentation/theme/auth_form_tokens.dart';

void main() {
  group('Auth shared form visual contracts', () {
    test('keeps shared chrome geometry and typography', () {
      expect(AuthFormTokens.topBarHeight, 48.0);
      expect(AuthFormTokens.titleFontSize, 20.0);
      expect(AuthFormTokens.titleFontWeight, FontWeight.w700);
      expect(AuthFormTokens.passwordVisibilityIconSize, 22.0);
      expect(AuthFormTokens.footerFontSize, 14.0);
      expect(AuthFormTokens.footerLinkFontWeight, FontWeight.w700);
    });

    test('reuses exact foundation spacing roles', () {
      expect(AuthFormTokens.socialProviderGap, TioSpacing.medium);
      expect(AuthFormTokens.footerLinkHorizontalPadding, TioSpacing.extraSmall);
      expect(AuthFormTokens.footerLinkVerticalPadding, TioSpacing.small);
    });
  });
}

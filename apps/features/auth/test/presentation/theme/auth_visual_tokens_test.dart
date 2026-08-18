import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';
import 'package:tio_feature_auth/src/presentation/theme/auth_visual_tokens.dart';

void main() {
  group('Auth inline error visual contracts', () {
    test('reuses shared spacing and radius roles', () {
      expect(AuthVisualTokens.inlineErrorHorizontalPadding, TioSpacing.large);
      expect(AuthVisualTokens.inlineErrorVerticalPadding, TioSpacing.medium);
      expect(AuthVisualTokens.inlineErrorRadius, TioRadius.large);
    });

    test('keeps the audited state presentation', () {
      expect(AuthVisualTokens.inlineErrorContainerOpacity, 0.10);
      expect(AuthVisualTokens.inlineErrorIconSize, 18.0);
      expect(AuthVisualTokens.inlineErrorContentGap, 10.0);
      expect(AuthVisualTokens.inlineErrorFontSize, 13.0);
    });
  });

  group('Auth floating error visual contracts', () {
    test('preserves shared geometry and exact banner colors', () {
      expect(AuthVisualTokens.floatingErrorHorizontalPadding, TioSpacing.large);
      expect(AuthVisualTokens.floatingErrorVerticalPadding, TioSpacing.medium);
      expect(AuthVisualTokens.floatingErrorRadius, TioRadius.large);
      expect(AuthVisualTokens.floatingErrorElevation, 6.0);
      expect(AuthVisualTokens.floatingErrorShadowBaseColor, const Color(0xFF000000));
      expect(AuthVisualTokens.floatingErrorShadowOpacity, 0.30);
      expect(AuthVisualTokens.floatingErrorShadowBlurRadius, 10.0);
      expect(AuthVisualTokens.floatingErrorShadowOffset, const Offset(0, 4));
      expect(AuthVisualTokens.floatingErrorContentColor, const Color(0xFFFFFFFF));
      expect(AuthVisualTokens.floatingErrorDismissColor, const Color(0xB3FFFFFF));
    });

    test('preserves banner typography and action presentation', () {
      expect(AuthVisualTokens.floatingErrorIconSize, 20.0);
      expect(AuthVisualTokens.floatingErrorContentGap, TioSpacing.medium);
      expect(AuthVisualTokens.floatingErrorDismissIconSize, 18.0);
      expect(AuthVisualTokens.floatingErrorMessageFontSize, 13.0);
      expect(AuthVisualTokens.floatingErrorLoginMessageFontWeight, FontWeight.w500);
      expect(AuthVisualTokens.floatingErrorSignupMessageFontWeight, FontWeight.w600);
      expect(AuthVisualTokens.signupRecoveryActionBackgroundColor, const Color(0x32FFFFFF));
      expect(AuthVisualTokens.signupRecoveryActionHorizontalPadding, 10.0);
      expect(AuthVisualTokens.signupRecoveryActionVerticalPadding, TioSpacing.extraSmall);
      expect(AuthVisualTokens.signupRecoveryActionRadius, TioRadius.small);
      expect(AuthVisualTokens.signupRecoveryActionFontSize, 12.0);
      expect(AuthVisualTokens.signupRecoveryActionFontWeight, FontWeight.w800);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_account_setup/src/presentation/theme/account_setup_visual_tokens.dart';

void main() {
  group('Account Setup visual contracts', () {
    test('keeps flow layout and status treatment', () {
      expect(AccountSetupVisualTokens.topBarHeight, 48.0);
      expect(AccountSetupVisualTokens.contentMaxWidth, 480.0);
      expect(AccountSetupVisualTokens.footerDividerOpacity, 0.18);
      expect(AccountSetupVisualTokens.statusFontWeight, FontWeight.w600);
      expect(AccountSetupVisualTokens.busyIndicatorSize, 20.0);
      expect(AccountSetupVisualTokens.busyIndicatorStrokeWidth, 2.0);
    });

    test('keeps mobile helper typography', () {
      expect(AccountSetupVisualTokens.helperFontSize, 12.0);
      expect(AccountSetupVisualTokens.helperLineHeight, 1.3);
    });
  });
}

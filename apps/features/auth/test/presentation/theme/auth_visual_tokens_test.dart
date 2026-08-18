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
}

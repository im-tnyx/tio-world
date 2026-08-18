import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('OTP dialog visual contracts', () {
    test('keeps the audited panel and input geometry', () {
      expect(TioDialogTokens.otpInsetHorizontal, 32.0);
      expect(TioDialogTokens.otpPanelTopPadding, 28.0);
      expect(TioDialogTokens.otpPanelRadius, 28.0);
      expect(TioDialogTokens.otpTitleToInputGap, 18.0);
      expect(TioDialogTokens.otpInputHeight, 52.0);
      expect(TioDialogTokens.otpInputRadius, 26.0);
      expect(TioDialogTokens.otpInputHorizontalPadding, 20.0);
    });

    test('keeps the audited typography and state visuals', () {
      expect(TioDialogTokens.otpTitleFontSize, 16.0);
      expect(TioDialogTokens.otpInputFontSize, 20.0);
      expect(TioDialogTokens.otpInputLetterSpacing, 6.0);
      expect(TioDialogTokens.otpPanelOutlineAlpha, 30);
      expect(TioDialogTokens.otpErrorOutlineAlpha, 90);
      expect(TioDialogTokens.otpInputOutlineAlpha, 40);
      expect(TioDialogTokens.otpActionRadius, 20.0);
      expect(TioDialogTokens.otpLoadingSize, 18.0);
      expect(TioDialogTokens.otpLoadingStrokeWidth, 2.0);
    });
  });
}

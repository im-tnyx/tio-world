import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('OTP dialog visual contracts', () {
    test('keeps the audited panel and input geometry', () {
      expect(TioOtpDialogTokens.insetHorizontal, 32.0);
      expect(TioOtpDialogTokens.panelTopPadding, 28.0);
      expect(TioOtpDialogTokens.panelRadius, 28.0);
      expect(TioOtpDialogTokens.titleToInputGap, 18.0);
      expect(TioOtpDialogTokens.inputHeight, 52.0);
      expect(TioOtpDialogTokens.inputRadius, 26.0);
      expect(TioOtpDialogTokens.inputHorizontalPadding, 20.0);
    });

    test('keeps the audited typography and state visuals', () {
      expect(TioOtpDialogTokens.titleFontSize, 16.0);
      expect(TioOtpDialogTokens.inputFontSize, 20.0);
      expect(TioOtpDialogTokens.inputLetterSpacing, 6.0);
      expect(TioOtpDialogTokens.panelOutlineAlpha, 30);
      expect(TioOtpDialogTokens.errorOutlineAlpha, 90);
      expect(TioOtpDialogTokens.inputOutlineAlpha, 40);
      expect(TioOtpDialogTokens.actionRadius, 20.0);
      expect(TioOtpDialogTokens.loadingSize, 18.0);
      expect(TioOtpDialogTokens.loadingStrokeWidth, 2.0);
    });
  });
}

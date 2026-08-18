import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical stroke widths', () {
    test('physical widths remain exact', () {
      expect(TioStroke.width075, 0.75);
      expect(TioStroke.width1, 1.0);
      expect(TioStroke.width125, 1.25);
      expect(TioStroke.width15, 1.5);
      expect(TioStroke.width2, 2.0);
      expect(TioStroke.width25, 2.5);
      expect(TioStroke.width3, 3.0);
      expect(TioStroke.width4, 4.0);
      expect(TioStroke.width6, 6.0);
    });

    test('button and card roles alias canonical widths', () {
      expect(TioButtonTokens.loadingIndicatorStrokeWidth, TioStroke.width2);
      expect(TioButtonTokens.outlineWidth, TioStroke.width1);
      expect(TioButtonTokens.focusedOutlineWidth, TioStroke.width2);

      expect(TioCardTokens.borderThin, TioStroke.width075);
      expect(TioCardTokens.borderThick, TioStroke.width125);
      expect(TioCardTokens.borderBold, TioStroke.width2);
    });

    test('input roles alias canonical widths', () {
      expect(TioInputTokens.outlineWidth, TioStroke.width075);
      expect(TioInputTokens.focusedOutlineWidth, TioStroke.width125);
      expect(TioInputTokens.mobileVerifiedOutlineWidth, TioStroke.width15);
      expect(TioInputTokens.mobileDefaultOutlineWidth, TioStroke.width1);
      expect(TioInputTokens.usernameCheckingStrokeWidth, TioStroke.width2);
      expect(TioInputTokens.usernameFocusedOutlineWidth, TioStroke.width2);
    });

    test('avatar, dialog, navigation and sheet roles alias canonical widths', () {
      expect(TioAvatarTokens.plusRingWidth, TioStroke.width3);
      expect(TioAvatarTokens.smallPlusRingWidth, TioStroke.width15);
      expect(TioAvatarTokens.proFrameWidth, TioStroke.width4);
      expect(TioAvatarTokens.smallProFrameWidth, TioStroke.width15);

      expect(TioOtpDialogTokens.loadingStrokeWidth, TioStroke.width2);
      expect(TioDialogTokens.deleteHoldStrokeWidth, TioStroke.width6);
      expect(
        TioDialogTokens.deleteHoldLoadingStrokeWidth,
        TioStroke.width25,
      );

      expect(TioNavigationTokens.aiTabInactiveOutlineWidth, TioStroke.width15);
      expect(TioRemoveImageSheetTokens.actionOutlineWidth, TioStroke.width1);
    });
  });
}

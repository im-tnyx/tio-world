import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical opacity primitives', () {
    test('normalized opacity values stay exact', () {
      expect(TioOpacity.opacity08, 0.08);
      expect(TioOpacity.opacity09, 0.09);
      expect(TioOpacity.opacity10, 0.10);
      expect(TioOpacity.opacity12, 0.12);
      expect(TioOpacity.opacity14, 0.14);
      expect(TioOpacity.opacity16, 0.16);
      expect(TioOpacity.opacity30, 0.30);
      expect(TioOpacity.opacity35, 0.35);
      expect(TioOpacity.opacity38, 0.38);
      expect(TioOpacity.opacity40, 0.40);
      expect(TioOpacity.opacity45, 0.45);
      expect(TioOpacity.opacity50, 0.50);
      expect(TioOpacity.opacity60, 0.60);
      expect(TioOpacity.opacity70, 0.70);
      expect(TioOpacity.opacity72, 0.72);
    });

    test('component opacity roles alias canonical primitives', () {
      expect(TioButtonTokens.pressedStateOpacity, TioOpacity.opacity12);
      expect(TioButtonTokens.hoveredStateOpacity, TioOpacity.opacity08);
      expect(TioButtonTokens.disabledContentOpacity, TioOpacity.opacity38);
      expect(TioCardTokens.glassContainerOpacity, TioOpacity.opacity72);
      expect(TioCardTokens.glassBorderOpacity, TioOpacity.opacity16);
      expect(TioInputTokens.darkUnfocusedOutlineOpacity, TioOpacity.opacity35);
      expect(TioInputTokens.lightUnfocusedOutlineOpacity, TioOpacity.opacity45);
      expect(TioInputTokens.mobileVerifyContainerOpacity, TioOpacity.opacity09);
      expect(TioInputTokens.usernameHintOpacity, TioOpacity.opacity60);
      expect(TioNavigationTokens.indicatorOpacity, TioOpacity.opacity14);
      expect(TioNavigationTokens.aiTabGlowOpacity, TioOpacity.opacity30);
      expect(TioNavigationTokens.aiTabInactiveOutlineOpacity, TioOpacity.opacity40);
      expect(TioLegalTokens.bodyTextOpacity, TioOpacity.opacity70);
      expect(TioLegalTokens.linkUnderlineOpacity, TioOpacity.opacity50);
    });
  });

  group('canonical exact alpha primitives', () {
    test('0-255 alpha contracts stay byte-exact', () {
      expect(TioAlpha.alpha25, 25);
      expect(TioAlpha.alpha26, 26);
      expect(TioAlpha.alpha30, 30);
      expect(TioAlpha.alpha35, 35);
      expect(TioAlpha.alpha40, 40);
      expect(TioAlpha.alpha50, 50);
      expect(TioAlpha.alpha80, 80);
      expect(TioAlpha.alpha90, 90);
      expect(TioAlpha.alpha120, 120);
      expect(TioAlpha.alpha200, 200);
      expect(TioAlpha.alpha245, 245);
    });

    test('component alpha roles alias canonical primitives', () {
      expect(TioAvatarActionSheetTokens.dragHandleAlpha, TioAlpha.alpha50);
      expect(TioOtpDialogTokens.panelOutlineAlpha, TioAlpha.alpha30);
      expect(TioOtpDialogTokens.errorOutlineAlpha, TioAlpha.alpha90);
      expect(TioDobPickerTokens.sheetOutlineAlpha, TioAlpha.alpha25);
      expect(TioDobPickerTokens.unselectedTextAlpha, TioAlpha.alpha120);
      expect(TioInputTokens.usernameSuggestionOutlineAlpha, TioAlpha.alpha80);
      expect(TioMeasurementPickerTokens.closeContainerAlpha, TioAlpha.alpha50);
      expect(TioMeasurementPickerTokens.inputOutlineAlpha, TioAlpha.alpha40);
      expect(TioRemoveImageSheetTokens.actionOutlineAlpha, TioAlpha.alpha25);
      expect(TioWheelPickerTokens.selectionSurfaceAlpha, TioAlpha.alpha200);
    });
  });
}

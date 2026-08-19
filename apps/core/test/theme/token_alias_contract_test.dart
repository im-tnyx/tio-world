import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('foundation token contracts', () {
    test('spacing scale keeps the approved canonical rhythm', () {
      expect(TioSpacing.none, 0.0);
      expect(TioSpacing.xxs, 2.0);
      expect(TioSpacing.xs, 4.0);
      expect(TioSpacing.sm, 8.0);
      expect(TioSpacing.md, 12.0);
      expect(TioSpacing.lg, 16.0);
      expect(TioSpacing.xl, 24.0);
      expect(TioSpacing.xxl, 32.0);
    });
  });

  group('component token foundation relationships', () {
    test('spacing roles stay aligned with foundation semantics', () {
      expect(TioButtonTokens.contentGap, TioSpacing.sm);
      expect(TioCardTokens.padding, TioSpacing.lg);
      expect(TioInputTokens.horizontalPadding, TioSpacing.lg);
      expect(TioInputTokens.compactContentHorizontalPadding, TioSpacing.sm);
      expect(TioInputTokens.standardContentVerticalPadding, TioSpacing.lg);
      expect(TioMeasurementPickerTokens.headerSubtitleGap, TioSpacing.md);
      expect(TioNavigationTokens.planContentGap, TioSpacing.xs);
      expect(TioSheetTokens.padding, TioSpacing.lg);
      expect(TioSheetTokens.titleGap, TioSpacing.md);
    });

    test('radius roles stay aligned with foundation semantics', () {
      expect(TioButtonTokens.radius, TioRadius.full);
      expect(TioCardTokens.radius, TioRadius.lg);
      expect(TioCardTokens.radiusItem, TioRadius.sm);
      expect(TioNavigationTokens.itemRadius, TioRadius.lg);
      expect(TioSheetTokens.radius, TioRadius.xl);
    });

    test('component-owned values keep audited runtime contracts', () {
      expect(TioCardTokens.materialThemeRadius, 20.0);
      expect(TioCardTokens.materialThemeElevation, 0.0);
      expect(TioCardTokens.glassContainerOpacity, 0.72);
      expect(TioCardTokens.glassBorderOpacity, 0.16);
      expect(TioOtpDialogTokens.shadowBlurRadius, 30.0);
      expect(TioOtpDialogTokens.shadowOffsetY, 10.0);
      expect(TioInputTokens.radius, 14.0);
      expect(TioInputTokens.outlineWidth, 0.75);
      expect(TioInputTokens.focusedOutlineWidth, 1.25);
      expect(TioInputTokens.darkUnfocusedOutlineOpacity, 0.35);
      expect(TioInputTokens.lightUnfocusedOutlineOpacity, 0.45);
      expect(TioInputTokens.compactTextFontSize, 16.0);
      expect(TioInputTokens.labelFontSize, 14.0);
      expect(TioInputTokens.compactHintFontSize, 15.0);
      expect(TioInputTokens.standardHintFontSize, 14.0);
      expect(TioInputTokens.compactContentVerticalPadding, 10.0);
      expect(TioInputTokens.mobileCountryToFieldGap, 14.0);
      expect(TioInputTokens.mobileFieldHeight, 56.0);
      expect(TioInputTokens.mobileCountryFlagFontSize, 22.0);
      expect(TioInputTokens.mobileCountryCodeFontSize, 16.0);
      expect(TioInputTokens.mobileTextFontSize, 16.0);
      expect(TioInputTokens.mobileTextLetterSpacing, 0.5);
      expect(TioInputTokens.mobileVerifiedOutlineOpacity, 0.45);
      expect(TioInputTokens.mobileDefaultOutlineOpacity, 0.16);
      expect(TioInputTokens.mobileVerifiedOutlineWidth, 1.5);
      expect(TioInputTokens.mobileDefaultOutlineWidth, 1.0);
      expect(TioInputTokens.mobileVerifiedIconSize, 22.0);
      expect(TioInputTokens.mobileVerifyHorizontalPadding, 10.0);
      expect(TioInputTokens.mobileVerifyVerticalPadding, 5.0);
      expect(TioInputTokens.mobileVerifyContainerOpacity, 0.09);
      expect(TioInputTokens.mobileVerifyLabelFontSize, 12.0);
      expect(TioInputTokens.usernameIconSize, 20.0);
      expect(TioInputTokens.usernameCheckingIndicatorSize, 16.0);
      expect(TioInputTokens.usernameCheckingStrokeWidth, 2.0);
      expect(TioInputTokens.usernameHintOpacity, 0.60);
      expect(TioInputTokens.usernameContentVerticalPadding, 14.0);
      expect(TioInputTokens.usernameOutlineOpacity, 0.40);
      expect(TioInputTokens.usernameFocusedOutlineWidth, 2.0);
      expect(TioInputTokens.usernameSupportingGap, 6.0);
      expect(TioInputTokens.usernameSuggestionRadius, 20.0);
      expect(TioInputTokens.usernameSuggestionOutlineAlpha, 80);
      expect(TioLegalTokens.defaultFontSize, 12.0);
      expect(TioLegalTokens.bodyTextOpacity, 0.70);
      expect(TioLegalTokens.linkUnderlineOpacity, 0.50);
      expect(TioLegalTokens.bodyLineHeight, 1.5);
      expect(TioMeasurementPickerTokens.sheetOutlineAlpha, 25);
      expect(TioMeasurementPickerTokens.titleFontSize, 24.0);
      expect(TioMeasurementPickerTokens.closeButtonSize, 32.0);
      expect(TioMeasurementPickerTokens.subtitleFontSize, 14.0);
      expect(TioMeasurementPickerTokens.inputSectionGap, 28.0);
      expect(TioMeasurementPickerTokens.inputHeight, 64.0);
      expect(TioMeasurementPickerTokens.inputRadius, 18.0);
      expect(TioMeasurementPickerTokens.inputOutlineAlpha, 40);
      expect(TioMeasurementPickerTokens.inputTextFontSize, 24.0);
      expect(TioMeasurementPickerTokens.unitFontSize, 18.0);
      expect(TioMeasurementPickerTokens.dualInputGap, 14.0);
      expect(TioNavigationTokens.labelTopPadding, 2.0);
      expect(TioNavigationTokens.topBarLeadingWidth, 72.0);
      expect(TioNavigationTokens.planIconSize, 14.0);
      expect(TioNavigationTokens.planPlusAccentColor, const Color(0xFFF59E0B));

      expect(TioNavigationTokens.iconSize, 22.0);
      expect(TioNavigationTokens.aiTabActivePadding, 5.0);
      expect(TioNavigationTokens.aiTabInactivePadding, 4.0);
      expect(TioNavigationTokens.aiTabIconSize, 14.0);
      expect(TioNavigationTokens.aiTabGlowOpacity, 0.30);
      expect(TioNavigationTokens.aiTabGlowBlurRadius, 6.0);
      expect(TioNavigationTokens.aiTabGlowOffsetY, 2.0);
      expect(TioNavigationTokens.aiTabInactiveOutlineOpacity, 0.40);
      expect(TioNavigationTokens.aiTabInactiveOutlineWidth, 1.5);

      expect(TioAvatarTokens.smallPlusRingWidth, 1.5);
      expect(TioAvatarTokens.plusRingGap, 4.0);
      expect(TioAvatarTokens.smallPlusRingGap, 2.0);
      expect(TioAvatarTokens.smallProFrameWidth, 1.5);
      expect(TioAvatarTokens.smallProFramePadding, 2.0);
    });
  });
}

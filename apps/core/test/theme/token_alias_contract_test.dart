import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('foundation token contracts', () {
    test('spacing scale keeps the approved rhythm', () {
      expect(TioSpacing.extraSmall, 4.0);
      expect(TioSpacing.small, 8.0);
      expect(TioSpacing.medium, 12.0);
      expect(TioSpacing.large, 16.0);
      expect(TioSpacing.extraLarge, 24.0);
    });
  });

  group('component token foundation aliases', () {
    test('spacing aliases stay aligned with foundation semantics', () {
      expect(TioButtonTokens.contentGap, TioSpacing.small);
      expect(TioCardTokens.padding, TioSpacing.large);
      expect(TioInputTokens.horizontalPadding, TioSpacing.large);
      expect(TioSheetTokens.padding, TioSpacing.large);
      expect(TioSheetTokens.titleGap, TioSpacing.medium);
    });

    test('radius aliases stay aligned with foundation semantics', () {
      expect(TioButtonTokens.radius, TioRadius.full);
      expect(TioCardTokens.radius, TioRadius.large);
      expect(TioCardTokens.radiusItem, TioRadius.small);
      expect(TioNavigationTokens.itemRadius, TioRadius.large);
      expect(TioSheetTokens.radius, TioRadius.extraLarge);
    });

    test('component-owned values keep audited runtime contracts', () {
      expect(TioCardTokens.materialThemeRadius, 20.0);
      expect(TioCardTokens.materialThemeElevation, 0.0);
      expect(TioCardTokens.glassContainerOpacity, 0.72);
      expect(TioCardTokens.glassBorderOpacity, 0.16);
      expect(TioDialogTokens.otpShadowColor, const Color(0x50000000));
      expect(TioDialogTokens.otpShadowBlurRadius, 30.0);
      expect(TioDialogTokens.otpShadowOffsetY, 10.0);
      expect(TioInputTokens.radius, 14.0);
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
      expect(TioLegalTokens.defaultFontSize, 12.0);
      expect(TioLegalTokens.bodyTextOpacity, 0.70);
      expect(TioLegalTokens.linkUnderlineOpacity, 0.50);
      expect(TioLegalTokens.bodyLineHeight, 1.5);
      expect(TioNavigationTokens.labelTopPadding, 2.0);

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

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_core/core.dart';

void main() {
  group('canonical geometry primitives', () {
    test('audited integer geometry values remain pixel-exact', () {
      expect(TioSize.dp0, 0.0);
      expect(TioSize.dp1, 1.0);
      expect(TioSize.dp2, 2.0);
      expect(TioSize.dp3, 3.0);
      expect(TioSize.dp4, 4.0);
      expect(TioSize.dp5, 5.0);
      expect(TioSize.dp6, 6.0);
      expect(TioSize.dp8, 8.0);
      expect(TioSize.dp10, 10.0);
      expect(TioSize.dp12, 12.0);
      expect(TioSize.dp14, 14.0);
      expect(TioSize.dp16, 16.0);
      expect(TioSize.dp18, 18.0);
      expect(TioSize.dp20, 20.0);
      expect(TioSize.dp22, 22.0);
      expect(TioSize.dp24, 24.0);
      expect(TioSize.dp26, 26.0);
      expect(TioSize.dp27, 27.0);
      expect(TioSize.dp28, 28.0);
      expect(TioSize.dp30, 30.0);
      expect(TioSize.dp32, 32.0);
      expect(TioSize.dp36, 36.0);
      expect(TioSize.dp38, 38.0);
      expect(TioSize.dp44, 44.0);
      expect(TioSize.dp46, 46.0);
      expect(TioSize.dp48, 48.0);
      expect(TioSize.dp52, 52.0);
      expect(TioSize.dp54, 54.0);
      expect(TioSize.dp56, 56.0);
      expect(TioSize.dp62, 62.0);
      expect(TioSize.dp64, 64.0);
      expect(TioSize.dp72, 72.0);
      expect(TioSize.dp100, 100.0);
      expect(TioSize.dp125, 125.0);
      expect(TioSize.dp140, 140.0);
      expect(TioSize.dp160, 160.0);
      expect(TioSize.dp200, 200.0);
      expect(TioSize.dp999, 999.0);
    });

    test('scalable spacing roles alias canonical geometry primitives', () {
      expect(TioSpacing.none, TioSize.dp0);
      expect(TioSpacing.xxs, TioSize.dp2);
      expect(TioSpacing.xs, TioSize.dp4);
      expect(TioSpacing.sm, TioSize.dp8);
      expect(TioSpacing.md, TioSize.dp12);
      expect(TioSpacing.lg, TioSize.dp16);
      expect(TioSpacing.xl, TioSize.dp24);
      expect(TioSpacing.xxl, TioSize.dp32);
    });

    test('legacy spacing names preserve current rendered values', () {
      expect(TioSpacing.extraSmall, TioSpacing.xs);
      expect(TioSpacing.small, TioSpacing.sm);
      expect(TioSpacing.medium, TioSpacing.md);
      expect(TioSpacing.large, TioSpacing.lg);
      expect(TioSpacing.extraLarge, TioSpacing.xl);
    });

    test('scalable radius roles alias canonical geometry primitives', () {
      expect(TioRadius.none, TioSize.dp0);
      expect(TioRadius.xs, TioSize.dp4);
      expect(TioRadius.sm, TioSize.dp8);
      expect(TioRadius.md, TioSize.dp12);
      expect(TioRadius.lg, TioSize.dp16);
      expect(TioRadius.xl, TioSize.dp24);
      expect(TioRadius.full, TioSize.dp999);
    });

    test('legacy radius names preserve current rendered values', () {
      expect(TioRadius.small, TioRadius.sm);
      expect(TioRadius.medium, TioRadius.md);
      expect(TioRadius.large, TioRadius.lg);
      expect(TioRadius.extraLarge, TioRadius.xl);
    });

    test('avatar geometry aliases canonical primitives', () {
      expect(TioAvatarTokens.compactSize, TioSize.dp24);
      expect(TioAvatarTokens.smallSize, TioSize.dp36);
      expect(TioAvatarTokens.mediumSize, TioSize.dp48);
      expect(TioAvatarTokens.largeSize, TioSize.dp100);
      expect(TioAvatarTokens.extraLargeSize, TioSize.dp160);
      expect(TioAvatarTokens.plusRingGap, TioSize.dp4);
      expect(TioAvatarTokens.smallPlusRingGap, TioSize.dp2);
      expect(TioAvatarTokens.smallProFramePadding, TioSize.dp2);
    });

    test('button and card geometry alias canonical owners', () {
      expect(TioButtonTokens.height, TioSize.dp46);
      expect(TioButtonTokens.minimumWidth, TioSize.dp0);
      expect(TioButtonTokens.horizontalPadding, TioSize.dp20);
      expect(TioButtonTokens.contentGap, TioSpacing.sm);
      expect(TioButtonTokens.loadingIndicatorSize, TioSize.dp18);

      expect(TioCardTokens.radius, TioRadius.lg);
      expect(TioCardTokens.radiusItem, TioRadius.sm);
      expect(TioCardTokens.padding, TioSpacing.lg);
      expect(TioCardTokens.materialThemeRadius, TioSize.dp20);
    });

    test('input geometry aliases canonical owners without normalization', () {
      expect(TioInputTokens.radius, TioSize.dp14);
      expect(TioInputTokens.minHeight, TioSize.dp52);
      expect(TioInputTokens.horizontalPadding, TioSpacing.lg);
      expect(TioInputTokens.compactContentVerticalPadding, TioSize.dp10);
      expect(TioInputTokens.compactContentHorizontalPadding, TioSpacing.sm);
      expect(TioInputTokens.standardContentVerticalPadding, TioSpacing.lg);
      expect(TioInputTokens.mobileCountryToFieldGap, TioSize.dp14);
      expect(TioInputTokens.mobileFieldHeight, TioSize.dp56);
      expect(TioInputTokens.mobileVerifiedIconSize, TioSize.dp22);
      expect(TioInputTokens.mobileVerifyHorizontalPadding, TioSize.dp10);
      expect(TioInputTokens.mobileVerifyVerticalPadding, TioSize.dp5);
      expect(TioInputTokens.usernameIconSize, TioSize.dp20);
      expect(TioInputTokens.usernameCheckingIndicatorSize, TioSize.dp16);
      expect(TioInputTokens.usernameContentVerticalPadding, TioSize.dp14);
      expect(TioInputTokens.usernameSupportingGap, TioSize.dp6);
      expect(TioInputTokens.usernameSuggestionRadius, TioSize.dp20);
      expect(TioInputTokens.usernameSuggestionVerticalPadding, TioSize.dp6);
    });

    test('navigation geometry aliases canonical owners without normalization', () {
      expect(TioNavigationTokens.bottomBarHeight, TioSize.dp62);
      expect(TioNavigationTokens.itemRadius, TioRadius.lg);
      expect(TioNavigationTokens.iconSize, TioSize.dp22);
      expect(TioNavigationTokens.labelTopPadding, TioSpacing.xxs);
      expect(TioNavigationTokens.topBarLeadingWidth, TioSize.dp72);
      expect(TioNavigationTokens.planPillWidth, TioSize.dp125);
      expect(TioNavigationTokens.planPillHeight, TioSize.dp32);
      expect(TioNavigationTokens.planIconSize, TioSize.dp14);
      expect(TioNavigationTokens.planContentGap, TioSpacing.xs);
      expect(TioNavigationTokens.aiTabActivePadding, TioSize.dp5);
      expect(TioNavigationTokens.aiTabInactivePadding, TioSpacing.xs);
      expect(TioNavigationTokens.aiTabIconSize, TioSize.dp14);
      expect(TioNavigationTokens.aiTabGlowBlurRadius, TioSize.dp6);
      expect(TioNavigationTokens.aiTabGlowOffsetY, TioSize.dp2);
    });

    test('avatar action sheet geometry aliases canonical owners', () {
      expect(TioAvatarActionSheetTokens.sheetRadius, TioRadius.lg);
      expect(TioAvatarActionSheetTokens.dragHandleWidth, TioSize.dp36);
      expect(TioAvatarActionSheetTokens.dragHandleHeight, TioSize.dp4);
      expect(TioAvatarActionSheetTokens.dragHandleRadius, TioSize.dp2);
      expect(TioAvatarActionSheetTokens.handleToTitleGap, TioSpacing.lg);
      expect(TioAvatarActionSheetTokens.titleToOptionsGap, TioSpacing.md);
      expect(TioAvatarActionSheetTokens.optionIconPadding, TioSpacing.sm);
      expect(TioAvatarActionSheetTokens.optionIconSize, TioSize.dp20);
      expect(TioAvatarActionSheetTokens.bottomGap, TioSpacing.sm);
    });

    test('dialog geometry aliases exact canonical sizes', () {
      expect(TioDialogTokens.otpInsetHorizontal, TioSize.dp32);
      expect(TioDialogTokens.otpPanelTopPadding, TioSize.dp28);
      expect(TioDialogTokens.otpPanelRadius, TioSize.dp28);
      expect(TioDialogTokens.otpShadowBlurRadius, TioSize.dp30);
      expect(TioDialogTokens.otpShadowOffsetY, TioSize.dp10);
      expect(TioDialogTokens.otpInputHeight, TioSize.dp52);
      expect(TioDialogTokens.otpInputRadius, TioSize.dp26);
      expect(TioDialogTokens.otpActionRadius, TioSize.dp20);
      expect(TioDialogTokens.deleteActionButtonHeight, TioSize.dp54);
      expect(TioDialogTokens.deleteActionButtonRadius, TioSize.dp27);
      expect(TioDialogTokens.deleteHoldControlSize, TioSize.dp140);
      expect(TioDialogTokens.deleteHoldButtonSize, TioSize.dp100);
      expect(TioDialogTokens.deleteHoldGlowSpreadRadius, TioSize.dp2);
      expect(TioDialogTokens.deleteCompletedIconContainerSize, TioSize.dp72);
      expect(TioDialogTokens.deleteCompletedIconSize, TioSize.dp38);
    });

    test('picker geometry aliases canonical owners without ratio changes', () {
      expect(TioWheelPickerTokens.viewportHeight, TioSize.dp200);
      expect(TioWheelPickerTokens.selectionHeight, TioSize.dp48);
      expect(TioWheelPickerTokens.selectionHorizontalMargin, TioSpacing.lg);
      expect(TioWheelPickerTokens.itemExtent, TioSize.dp44);

      expect(TioDobPickerTokens.closeIconSize, TioSize.dp24);
      expect(TioDobPickerTokens.closeSplashRadius, TioSize.dp20);
      expect(TioDobPickerTokens.headerSubtitleGap, TioSize.dp6);
      expect(TioDobPickerTokens.columnHeaderToWheelGap, TioSpacing.md);
      expect(TioDobPickerTokens.perspective, 0.004);
      expect(TioDobPickerTokens.diameterRatio, 1.3);

      expect(TioMeasurementPickerTokens.closeButtonSize, TioSize.dp32);
      expect(TioMeasurementPickerTokens.closeIconSize, TioSize.dp18);
      expect(TioMeasurementPickerTokens.closeSplashRadius, TioSize.dp16);
      expect(TioMeasurementPickerTokens.headerSubtitleGap, TioSpacing.md);
      expect(TioMeasurementPickerTokens.inputSectionGap, TioSize.dp28);
      expect(TioMeasurementPickerTokens.inputHeight, TioSize.dp64);
      expect(TioMeasurementPickerTokens.inputRadius, TioSize.dp18);
      expect(TioMeasurementPickerTokens.inputHorizontalPadding, TioSize.dp20);
      expect(TioMeasurementPickerTokens.dualInputGap, TioSize.dp14);
    });

    test('sheet geometry aliases canonical owners', () {
      expect(TioRemoveImageSheetTokens.sheetRadius, TioRadius.xl);
      expect(TioRemoveImageSheetTokens.contentHorizontalPadding, TioSize.dp20);
      expect(TioRemoveImageSheetTokens.contentTopPadding, TioSpacing.lg);
      expect(TioRemoveImageSheetTokens.contentBottomPadding, TioSpacing.xl);
      expect(TioRemoveImageSheetTokens.closeButtonSize, TioSize.dp32);
      expect(TioRemoveImageSheetTokens.closeIconSize, TioSize.dp18);
      expect(TioRemoveImageSheetTokens.closeToTitleGap, TioSize.dp6);
      expect(TioRemoveImageSheetTokens.titleToSubtitleGap, TioSpacing.sm);
      expect(TioRemoveImageSheetTokens.subtitleToActionsGap, TioSize.dp26);
      expect(TioRemoveImageSheetTokens.actionRadius, TioSize.dp20);
      expect(TioRemoveImageSheetTokens.actionVerticalPadding, TioSpacing.lg);
      expect(TioRemoveImageSheetTokens.actionIconGap, TioSpacing.sm);
      expect(TioRemoveImageSheetTokens.removeIconSize, TioSize.dp20);
      expect(TioRemoveImageSheetTokens.cancelIconSize, TioSize.dp18);
      expect(TioRemoveImageSheetTokens.actionGap, TioSpacing.md);

      expect(TioSheetTokens.radius, TioRadius.xl);
      expect(TioSheetTokens.padding, TioSpacing.lg);
      expect(TioSheetTokens.titleGap, TioSpacing.md);
    });

    test('avatar ratios remain component-specific exact contracts', () {
      expect(TioAvatarTokens.roundedRadiusFactor, 0.28);
      expect(TioAvatarTokens.iconSizeFactor, 0.5);
      expect(TioAvatarTokens.textSizeFactor, 0.36);
    });
  });
}

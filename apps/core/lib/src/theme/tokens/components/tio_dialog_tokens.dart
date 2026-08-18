import '../foundation/tio_palette.dart';
import 'tio_delete_account_dialog_tokens.dart';
import 'tio_otp_dialog_tokens.dart';

/// Temporary compatibility facade while current core consumers migrate to the
/// focused reusable dialog contracts.
@Deprecated('Use TioOtpDialogTokens or TioDeleteAccountDialogTokens.')
abstract final class TioDialogTokens {
  static const otpInsetHorizontal = TioOtpDialogTokens.insetHorizontal;
  static const otpPanelTopPadding = TioOtpDialogTokens.panelTopPadding;
  static const otpPanelRadius = TioOtpDialogTokens.panelRadius;
  static const otpPanelOutlineAlpha = TioOtpDialogTokens.panelOutlineAlpha;

  /// Compatibility-only physical shadow color for unmigrated callers.
  /// Runtime dialog rendering resolves `context.tioShadows.elevatedPanelColor`.
  static const otpShadowColor = TioPalette.blackAlpha80;

  static const otpShadowBlurRadius = TioOtpDialogTokens.shadowBlurRadius;
  static const otpShadowOffsetY = TioOtpDialogTokens.shadowOffsetY;
  static const otpTitleFontSize = TioOtpDialogTokens.titleFontSize;
  static const otpTitleLetterSpacing = TioOtpDialogTokens.titleLetterSpacing;
  static const otpTitleToInputGap = TioOtpDialogTokens.titleToInputGap;
  static const otpInputHeight = TioOtpDialogTokens.inputHeight;
  static const otpInputRadius = TioOtpDialogTokens.inputRadius;
  static const otpErrorOutlineAlpha = TioOtpDialogTokens.errorOutlineAlpha;
  static const otpInputOutlineAlpha = TioOtpDialogTokens.inputOutlineAlpha;
  static const otpInputHorizontalPadding =
      TioOtpDialogTokens.inputHorizontalPadding;
  static const otpInputFontSize = TioOtpDialogTokens.inputFontSize;
  static const otpInputLetterSpacing = TioOtpDialogTokens.inputLetterSpacing;
  static const otpErrorFontSize = TioOtpDialogTokens.errorFontSize;
  static const otpSubtitleTopGap = TioOtpDialogTokens.subtitleTopGap;
  static const otpSubtitleFontSize = TioOtpDialogTokens.subtitleFontSize;
  static const otpSubtitleLineHeight = TioOtpDialogTokens.subtitleLineHeight;
  static const otpVerifyTopGap = TioOtpDialogTokens.verifyTopGap;
  static const otpActionRadius = TioOtpDialogTokens.actionRadius;
  static const otpActionHorizontalPadding =
      TioOtpDialogTokens.actionHorizontalPadding;
  static const otpActionContainerAlpha = TioOtpDialogTokens.actionContainerAlpha;
  static const otpLoadingSize = TioOtpDialogTokens.loadingSize;
  static const otpLoadingStrokeWidth = TioOtpDialogTokens.loadingStrokeWidth;
  static const otpActionFontSize = TioOtpDialogTokens.actionFontSize;
  static const otpActionLetterSpacing = TioOtpDialogTokens.actionLetterSpacing;
  static const otpBackTopGap = TioOtpDialogTokens.backTopGap;

  static const deleteHoldFillColor = TioDeleteAccountDialogTokens.holdFillColor;
  static const deleteHoldContentColor =
      TioDeleteAccountDialogTokens.holdContentColor;
  static const deleteOverlayBackgroundAlpha =
      TioDeleteAccountDialogTokens.overlayBackgroundAlpha;
  static const deleteCloseButtonSize =
      TioDeleteAccountDialogTokens.closeButtonSize;
  static const deleteCloseContainerAlpha =
      TioDeleteAccountDialogTokens.closeContainerAlpha;
  static const deleteCloseIconSize = TioDeleteAccountDialogTokens.closeIconSize;
  static const deleteCloseSplashRadius =
      TioDeleteAccountDialogTokens.closeSplashRadius;
  static const deleteHeadlineFontSize =
      TioDeleteAccountDialogTokens.headlineFontSize;
  static const deleteHeadlineLetterSpacing =
      TioDeleteAccountDialogTokens.headlineLetterSpacing;
  static const deleteBodyFontSize = TioDeleteAccountDialogTokens.bodyFontSize;
  static const deleteBodyLineHeight = TioDeleteAccountDialogTokens.bodyLineHeight;
  static const deleteWarningFontSize =
      TioDeleteAccountDialogTokens.warningFontSize;
  static const deleteActionSectionGap =
      TioDeleteAccountDialogTokens.actionSectionGap;
  static const deleteActionButtonHeight =
      TioDeleteAccountDialogTokens.actionButtonHeight;
  static const deleteActionButtonRadius =
      TioDeleteAccountDialogTokens.actionButtonRadius;
  static const deleteActionLabelFontSize =
      TioDeleteAccountDialogTokens.actionLabelFontSize;
  static const deleteActionContainerAlpha =
      TioDeleteAccountDialogTokens.actionContainerAlpha;
  static const deleteHoldHeadlineLineHeight =
      TioDeleteAccountDialogTokens.holdHeadlineLineHeight;
  static const deleteHoldBodyFontSize =
      TioDeleteAccountDialogTokens.holdBodyFontSize;
  static const deleteHoldControlTopGap =
      TioDeleteAccountDialogTokens.holdControlTopGap;
  static const deleteCountdownHeight =
      TioDeleteAccountDialogTokens.countdownHeight;
  static const deleteCountdownFontSize =
      TioDeleteAccountDialogTokens.countdownFontSize;
  static const deleteHoldControlSize =
      TioDeleteAccountDialogTokens.holdControlSize;
  static const deleteHoldStrokeWidth =
      TioDeleteAccountDialogTokens.holdStrokeWidth;
  static const deleteHoldTrackAlpha =
      TioDeleteAccountDialogTokens.holdTrackAlpha;
  static const deleteHoldButtonSize =
      TioDeleteAccountDialogTokens.holdButtonSize;
  static const deleteHoldGlowAlpha = TioDeleteAccountDialogTokens.holdGlowAlpha;
  static const deleteHoldGlowBlurRadius =
      TioDeleteAccountDialogTokens.holdGlowBlurRadius;
  static const deleteHoldGlowSpreadRadius =
      TioDeleteAccountDialogTokens.holdGlowSpreadRadius;
  static const deleteHoldLoadingStrokeWidth =
      TioDeleteAccountDialogTokens.holdLoadingStrokeWidth;
  static const deleteHoldActionGap =
      TioDeleteAccountDialogTokens.holdActionGap;
  static const deleteCompletedIconContainerSize =
      TioDeleteAccountDialogTokens.completedIconContainerSize;
  static const deleteCompletedIconContainerAlpha =
      TioDeleteAccountDialogTokens.completedIconContainerAlpha;
  static const deleteCompletedIconSize =
      TioDeleteAccountDialogTokens.completedIconSize;
  static const deleteCompletedIconGap =
      TioDeleteAccountDialogTokens.completedIconGap;
  static const deleteCompletedTitleFontSize =
      TioDeleteAccountDialogTokens.completedTitleFontSize;
  static const deleteCompletedTextGap =
      TioDeleteAccountDialogTokens.completedTextGap;
  static const deleteCompletedBodyFontSize =
      TioDeleteAccountDialogTokens.completedBodyFontSize;
  static const deleteCompletedBodyLineHeight =
      TioDeleteAccountDialogTokens.completedBodyLineHeight;
}

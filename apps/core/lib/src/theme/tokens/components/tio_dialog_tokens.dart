import '../foundation/tio_palette.dart';
import '../foundation/tio_stroke.dart';
import '../primitive/tio_alpha.dart';
import '../typography/tio_font_size.dart';
import '../typography/tio_letter_spacing.dart';
import '../typography/tio_line_height.dart';

class TioDialogTokens {
  const TioDialogTokens._();

  static const otpInsetHorizontal = 32.0;
  static const otpPanelTopPadding = 28.0;
  static const otpPanelRadius = 28.0;
  static const otpPanelOutlineAlpha = TioAlpha.alpha30;

  /// Compatibility-only physical shadow color for unmigrated callers.
  /// Runtime dialog rendering must resolve the semantic shadow color through
  /// `context.tioShadows.elevatedPanelColor` so theme modes can diverge later.
  static const otpShadowColor = TioPalette.blackAlpha80;

  static const otpShadowBlurRadius = 30.0;
  static const otpShadowOffsetY = 10.0;
  static const otpTitleFontSize = TioFontSize.size16;
  static const otpTitleLetterSpacing = TioLetterSpacing.negative02;
  static const otpTitleToInputGap = 18.0;
  static const otpInputHeight = 52.0;
  static const otpInputRadius = 26.0;
  static const otpErrorOutlineAlpha = TioAlpha.alpha90;
  static const otpInputOutlineAlpha = TioAlpha.alpha40;
  static const otpInputHorizontalPadding = 20.0;
  static const otpInputFontSize = TioFontSize.size20;
  static const otpInputLetterSpacing = TioLetterSpacing.positive60;
  static const otpErrorFontSize = TioFontSize.size12;
  static const otpSubtitleTopGap = 14.0;
  static const otpSubtitleFontSize = TioFontSize.size13;
  static const otpSubtitleLineHeight = TioLineHeight.height135;
  static const otpVerifyTopGap = 22.0;
  static const otpActionRadius = 20.0;
  static const otpActionHorizontalPadding = 28.0;
  static const otpActionContainerAlpha = TioAlpha.alpha40;
  static const otpLoadingSize = 18.0;
  static const otpLoadingStrokeWidth = TioStroke.width2;
  static const otpActionFontSize = TioFontSize.size13;
  static const otpActionLetterSpacing = TioLetterSpacing.positive08;
  static const otpBackTopGap = 14.0;

  static const deleteHoldFillColor = TioPalette.red550;
  static const deleteHoldContentColor = TioPalette.white;
  static const deleteOverlayBackgroundAlpha = TioAlpha.alpha245;
  static const deleteCloseButtonSize = 36.0;
  static const deleteCloseContainerAlpha = TioAlpha.alpha25;
  static const deleteCloseIconSize = 20.0;
  static const deleteCloseSplashRadius = 18.0;
  static const deleteHeadlineFontSize = TioFontSize.size28;
  static const deleteHeadlineLetterSpacing = TioLetterSpacing.negative05;
  static const deleteBodyFontSize = TioFontSize.size16;
  static const deleteBodyLineHeight = TioLineHeight.height140;
  static const deleteWarningFontSize = TioFontSize.size14;
  static const deleteActionSectionGap = 36.0;
  static const deleteActionButtonHeight = 54.0;
  static const deleteActionButtonRadius = 27.0;
  static const deleteActionLabelFontSize = TioFontSize.size16;
  static const deleteActionContainerAlpha = TioAlpha.alpha35;
  static const deleteHoldHeadlineLineHeight = TioLineHeight.height125;
  static const deleteHoldBodyFontSize = TioFontSize.size15;
  static const deleteHoldControlTopGap = 48.0;
  static const deleteCountdownHeight = 44.0;
  static const deleteCountdownFontSize = TioFontSize.size34;
  static const deleteHoldControlSize = 140.0;
  static const deleteHoldStrokeWidth = TioStroke.width6;
  static const deleteHoldTrackAlpha = TioAlpha.alpha25;
  static const deleteHoldButtonSize = 100.0;
  static const deleteHoldGlowAlpha = TioAlpha.alpha80;
  static const deleteHoldGlowBlurRadius = 20.0;
  static const deleteHoldGlowSpreadRadius = 2.0;
  static const deleteHoldLoadingStrokeWidth = TioStroke.width25;
  static const deleteHoldActionGap = 56.0;
  static const deleteCompletedIconContainerSize = 72.0;
  static const deleteCompletedIconContainerAlpha = TioAlpha.alpha30;
  static const deleteCompletedIconSize = 38.0;
  static const deleteCompletedIconGap = 20.0;
  static const deleteCompletedTitleFontSize = TioFontSize.size24;
  static const deleteCompletedTextGap = 10.0;
  static const deleteCompletedBodyFontSize = TioFontSize.size14;
  static const deleteCompletedBodyLineHeight = TioLineHeight.height135;
}

import '../foundation/tio_palette.dart';
import '../foundation/tio_stroke.dart';
import '../primitive/tio_alpha.dart';
import '../primitive/tio_size.dart';
import '../typography/tio_font_size.dart';
import '../typography/tio_letter_spacing.dart';
import '../typography/tio_line_height.dart';

class TioDialogTokens {
  const TioDialogTokens._();

  static const otpInsetHorizontal = TioSize.dp32;
  static const otpPanelTopPadding = TioSize.dp28;
  static const otpPanelRadius = TioSize.dp28;
  static const otpPanelOutlineAlpha = TioAlpha.alpha30;

  /// Compatibility-only physical shadow color for unmigrated callers.
  /// Runtime dialog rendering must resolve the semantic shadow color through
  /// `context.tioShadows.elevatedPanelColor` so theme modes can diverge later.
  static const otpShadowColor = TioPalette.blackAlpha80;

  static const otpShadowBlurRadius = TioSize.dp30;
  static const otpShadowOffsetY = TioSize.dp10;
  static const otpTitleFontSize = TioFontSize.size16;
  static const otpTitleLetterSpacing = TioLetterSpacing.negative02;
  static const otpTitleToInputGap = TioSize.dp18;
  static const otpInputHeight = TioSize.dp52;
  static const otpInputRadius = TioSize.dp26;
  static const otpErrorOutlineAlpha = TioAlpha.alpha90;
  static const otpInputOutlineAlpha = TioAlpha.alpha40;
  static const otpInputHorizontalPadding = TioSize.dp20;
  static const otpInputFontSize = TioFontSize.size20;
  static const otpInputLetterSpacing = TioLetterSpacing.positive60;
  static const otpErrorFontSize = TioFontSize.size12;
  static const otpSubtitleTopGap = TioSize.dp14;
  static const otpSubtitleFontSize = TioFontSize.size13;
  static const otpSubtitleLineHeight = TioLineHeight.height135;
  static const otpVerifyTopGap = TioSize.dp22;
  static const otpActionRadius = TioSize.dp20;
  static const otpActionHorizontalPadding = TioSize.dp28;
  static const otpActionContainerAlpha = TioAlpha.alpha40;
  static const otpLoadingSize = TioSize.dp18;
  static const otpLoadingStrokeWidth = TioStroke.width2;
  static const otpActionFontSize = TioFontSize.size13;
  static const otpActionLetterSpacing = TioLetterSpacing.positive08;
  static const otpBackTopGap = TioSize.dp14;

  static const deleteHoldFillColor = TioPalette.red550;
  static const deleteHoldContentColor = TioPalette.white;
  static const deleteOverlayBackgroundAlpha = TioAlpha.alpha245;
  static const deleteCloseButtonSize = TioSize.dp36;
  static const deleteCloseContainerAlpha = TioAlpha.alpha25;
  static const deleteCloseIconSize = TioSize.dp20;
  static const deleteCloseSplashRadius = TioSize.dp18;
  static const deleteHeadlineFontSize = TioFontSize.size28;
  static const deleteHeadlineLetterSpacing = TioLetterSpacing.negative05;
  static const deleteBodyFontSize = TioFontSize.size16;
  static const deleteBodyLineHeight = TioLineHeight.height140;
  static const deleteWarningFontSize = TioFontSize.size14;
  static const deleteActionSectionGap = TioSize.dp36;
  static const deleteActionButtonHeight = TioSize.dp54;
  static const deleteActionButtonRadius = TioSize.dp27;
  static const deleteActionLabelFontSize = TioFontSize.size16;
  static const deleteActionContainerAlpha = TioAlpha.alpha35;
  static const deleteHoldHeadlineLineHeight = TioLineHeight.height125;
  static const deleteHoldBodyFontSize = TioFontSize.size15;
  static const deleteHoldControlTopGap = TioSize.dp48;
  static const deleteCountdownHeight = TioSize.dp44;
  static const deleteCountdownFontSize = TioFontSize.size34;
  static const deleteHoldControlSize = TioSize.dp140;
  static const deleteHoldStrokeWidth = TioStroke.width6;
  static const deleteHoldTrackAlpha = TioAlpha.alpha25;
  static const deleteHoldButtonSize = TioSize.dp100;
  static const deleteHoldGlowAlpha = TioAlpha.alpha80;
  static const deleteHoldGlowBlurRadius = TioSize.dp20;
  static const deleteHoldGlowSpreadRadius = TioSize.dp2;
  static const deleteHoldLoadingStrokeWidth = TioStroke.width25;
  static const deleteHoldActionGap = TioSize.dp56;
  static const deleteCompletedIconContainerSize = TioSize.dp72;
  static const deleteCompletedIconContainerAlpha = TioAlpha.alpha30;
  static const deleteCompletedIconSize = TioSize.dp38;
  static const deleteCompletedIconGap = TioSize.dp20;
  static const deleteCompletedTitleFontSize = TioFontSize.size24;
  static const deleteCompletedTextGap = TioSize.dp10;
  static const deleteCompletedBodyFontSize = TioFontSize.size14;
  static const deleteCompletedBodyLineHeight = TioLineHeight.height135;
}

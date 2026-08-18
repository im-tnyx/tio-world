import '../foundation/tio_palette.dart';
import '../foundation/tio_stroke.dart';
import '../primitive/tio_alpha.dart';
import '../primitive/tio_size.dart';
import '../typography/tio_font_size.dart';
import '../typography/tio_letter_spacing.dart';
import '../typography/tio_line_height.dart';

/// Reusable visual contract for the Delete Account overlay/dialog flow.
///
/// Interaction timing and destructive business behavior are not theme tokens;
/// this contract owns only the reusable rendered visual roles.
abstract final class TioDeleteAccountDialogTokens {
  static const holdFillColor = TioPalette.red550;
  static const holdContentColor = TioPalette.white;
  static const overlayBackgroundAlpha = TioAlpha.alpha245;
  static const closeButtonSize = TioSize.dp36;
  static const closeContainerAlpha = TioAlpha.alpha25;
  static const closeIconSize = TioSize.dp20;
  static const closeSplashRadius = TioSize.dp18;
  static const headlineFontSize = TioFontSize.size28;
  static const headlineLetterSpacing = TioLetterSpacing.negative05;
  static const bodyFontSize = TioFontSize.size16;
  static const bodyLineHeight = TioLineHeight.height140;
  static const warningFontSize = TioFontSize.size14;
  static const actionSectionGap = TioSize.dp36;
  static const actionButtonHeight = TioSize.dp54;
  static const actionButtonRadius = TioSize.dp27;
  static const actionLabelFontSize = TioFontSize.size16;
  static const actionContainerAlpha = TioAlpha.alpha35;
  static const holdHeadlineLineHeight = TioLineHeight.height125;
  static const holdBodyFontSize = TioFontSize.size15;
  static const holdControlTopGap = TioSize.dp48;
  static const countdownHeight = TioSize.dp44;
  static const countdownFontSize = TioFontSize.size34;
  static const holdControlSize = TioSize.dp140;
  static const holdStrokeWidth = TioStroke.width6;
  static const holdTrackAlpha = TioAlpha.alpha25;
  static const holdButtonSize = TioSize.dp100;
  static const holdGlowAlpha = TioAlpha.alpha80;
  static const holdGlowBlurRadius = TioSize.dp20;
  static const holdGlowSpreadRadius = TioSize.dp2;
  static const holdLoadingStrokeWidth = TioStroke.width25;
  static const holdActionGap = TioSize.dp56;
  static const completedIconContainerSize = TioSize.dp72;
  static const completedIconContainerAlpha = TioAlpha.alpha30;
  static const completedIconSize = TioSize.dp38;
  static const completedIconGap = TioSize.dp20;
  static const completedTitleFontSize = TioFontSize.size24;
  static const completedTextGap = TioSize.dp10;
  static const completedBodyFontSize = TioFontSize.size14;
  static const completedBodyLineHeight = TioLineHeight.height135;
}

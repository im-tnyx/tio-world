import '../foundation/tio_spacing.dart';
import '../foundation/tio_stroke.dart';
import '../primitive/tio_alpha.dart';
import '../primitive/tio_opacity.dart';
import '../primitive/tio_size.dart';
import '../typography/tio_font_size.dart';
import '../typography/tio_letter_spacing.dart';

class TioInputTokens {
  const TioInputTokens._();

  static const radius = TioSize.dp14;
  static const minHeight = TioSize.dp52;
  static const horizontalPadding = TioSpacing.lg;
  static const outlineWidth = TioStroke.width075;
  static const focusedOutlineWidth = TioStroke.width125;
  static const darkUnfocusedOutlineOpacity = TioOpacity.opacity35;
  static const lightUnfocusedOutlineOpacity = TioOpacity.opacity45;
  static const compactTextFontSize = TioFontSize.size16;
  static const labelFontSize = TioFontSize.size14;
  static const compactHintFontSize = TioFontSize.size15;
  static const standardHintFontSize = TioFontSize.size14;
  static const compactContentVerticalPadding = TioSize.dp10;
  static const compactContentHorizontalPadding = TioSpacing.sm;
  static const standardContentVerticalPadding = TioSpacing.lg;

  static const mobileCountryToFieldGap = TioSize.dp14;
  static const mobileFieldHeight = TioSize.dp56;
  static const mobileCountryFlagFontSize = TioFontSize.size22;
  static const mobileCountryCodeFontSize = TioFontSize.size16;
  static const mobileTextFontSize = TioFontSize.size16;
  static const mobileTextLetterSpacing = TioLetterSpacing.positive05;
  static const mobileVerifiedOutlineOpacity = TioOpacity.opacity45;
  static const mobileDefaultOutlineOpacity = TioOpacity.opacity16;
  static const mobileVerifiedOutlineWidth = TioStroke.width15;
  static const mobileDefaultOutlineWidth = TioStroke.width1;
  static const mobileVerifiedIconSize = TioSize.dp22;
  static const mobileVerifyHorizontalPadding = TioSize.dp10;
  static const mobileVerifyVerticalPadding = TioSize.dp5;
  static const mobileVerifyContainerOpacity = TioOpacity.opacity09;
  static const mobileVerifyLabelFontSize = TioFontSize.size12;

  static const usernameIconSize = TioSize.dp20;
  static const usernameCheckingIndicatorSize = TioSize.dp16;
  static const usernameCheckingStrokeWidth = TioStroke.width2;
  static const usernameHintOpacity = TioOpacity.opacity60;
  static const usernameContentVerticalPadding = TioSize.dp14;
  static const usernameOutlineOpacity = TioOpacity.opacity40;
  static const usernameFocusedOutlineWidth = TioStroke.width2;
  static const usernameSupportingGap = TioSize.dp6;
  static const usernameFeedbackFontSize = TioFontSize.size12;
  static const usernameSuggestionRadius = TioSize.dp20;
  static const usernameSuggestionVerticalPadding = TioSize.dp6;
  static const usernameSuggestionOutlineAlpha = TioAlpha.alpha80;
  static const usernameSuggestionFontSize = TioFontSize.size13;
}

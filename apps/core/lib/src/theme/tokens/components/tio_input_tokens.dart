import '../foundation/tio_spacing.dart';
import '../primitive/tio_alpha.dart';
import '../primitive/tio_opacity.dart';
import '../typography/tio_font_size.dart';
import '../typography/tio_letter_spacing.dart';

class TioInputTokens {
  const TioInputTokens._();

  static const radius = 14.0;
  static const minHeight = 52.0;
  static const horizontalPadding = TioSpacing.large;
  static const outlineWidth = 0.75;
  static const focusedOutlineWidth = 1.25;
  static const darkUnfocusedOutlineOpacity = TioOpacity.opacity35;
  static const lightUnfocusedOutlineOpacity = TioOpacity.opacity45;
  static const compactTextFontSize = TioFontSize.size16;
  static const labelFontSize = TioFontSize.size14;
  static const compactHintFontSize = TioFontSize.size15;
  static const standardHintFontSize = TioFontSize.size14;
  static const compactContentVerticalPadding = 10.0;
  static const compactContentHorizontalPadding = TioSpacing.small;
  static const standardContentVerticalPadding = TioSpacing.large;

  static const mobileCountryToFieldGap = 14.0;
  static const mobileFieldHeight = 56.0;
  static const mobileCountryFlagFontSize = TioFontSize.size22;
  static const mobileCountryCodeFontSize = TioFontSize.size16;
  static const mobileTextFontSize = TioFontSize.size16;
  static const mobileTextLetterSpacing = TioLetterSpacing.positive05;
  static const mobileVerifiedOutlineOpacity = TioOpacity.opacity45;
  static const mobileDefaultOutlineOpacity = TioOpacity.opacity16;
  static const mobileVerifiedOutlineWidth = 1.5;
  static const mobileDefaultOutlineWidth = 1.0;
  static const mobileVerifiedIconSize = 22.0;
  static const mobileVerifyHorizontalPadding = 10.0;
  static const mobileVerifyVerticalPadding = 5.0;
  static const mobileVerifyContainerOpacity = TioOpacity.opacity09;
  static const mobileVerifyLabelFontSize = TioFontSize.size12;

  static const usernameIconSize = 20.0;
  static const usernameCheckingIndicatorSize = 16.0;
  static const usernameCheckingStrokeWidth = 2.0;
  static const usernameHintOpacity = TioOpacity.opacity60;
  static const usernameContentVerticalPadding = 14.0;
  static const usernameOutlineOpacity = TioOpacity.opacity40;
  static const usernameFocusedOutlineWidth = 2.0;
  static const usernameSupportingGap = 6.0;
  static const usernameFeedbackFontSize = TioFontSize.size12;
  static const usernameSuggestionRadius = 20.0;
  static const usernameSuggestionVerticalPadding = 6.0;
  static const usernameSuggestionOutlineAlpha = TioAlpha.alpha80;
  static const usernameSuggestionFontSize = TioFontSize.size13;
}

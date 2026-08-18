import '../foundation/tio_stroke.dart';
import '../primitive/tio_alpha.dart';
import '../primitive/tio_size.dart';
import '../typography/tio_font_size.dart';
import '../typography/tio_letter_spacing.dart';
import '../typography/tio_line_height.dart';

/// Reusable visual contract for [TioOtpVerificationDialog].
///
/// Physical values alias governed core primitives; runtime theme-dependent
/// colors and shadows remain resolved by the dialog through BuildContext.
abstract final class TioOtpDialogTokens {
  static const insetHorizontal = TioSize.dp32;
  static const panelTopPadding = TioSize.dp28;
  static const panelRadius = TioSize.dp28;
  static const panelOutlineAlpha = TioAlpha.alpha30;
  static const shadowBlurRadius = TioSize.dp30;
  static const shadowOffsetY = TioSize.dp10;
  static const titleFontSize = TioFontSize.size16;
  static const titleLetterSpacing = TioLetterSpacing.negative02;
  static const titleToInputGap = TioSize.dp18;
  static const inputHeight = TioSize.dp52;
  static const inputRadius = TioSize.dp26;
  static const errorOutlineAlpha = TioAlpha.alpha90;
  static const inputOutlineAlpha = TioAlpha.alpha40;
  static const inputHorizontalPadding = TioSize.dp20;
  static const inputFontSize = TioFontSize.size20;
  static const inputLetterSpacing = TioLetterSpacing.positive60;
  static const errorFontSize = TioFontSize.size12;
  static const subtitleTopGap = TioSize.dp14;
  static const subtitleFontSize = TioFontSize.size13;
  static const subtitleLineHeight = TioLineHeight.height135;
  static const verifyTopGap = TioSize.dp22;
  static const actionRadius = TioSize.dp20;
  static const actionHorizontalPadding = TioSize.dp28;
  static const actionContainerAlpha = TioAlpha.alpha40;
  static const loadingSize = TioSize.dp18;
  static const loadingStrokeWidth = TioStroke.width2;
  static const actionFontSize = TioFontSize.size13;
  static const actionLetterSpacing = TioLetterSpacing.positive08;
  static const backTopGap = TioSize.dp14;
}

import '../foundation/tio_spacing.dart';
import '../primitive/tio_alpha.dart';
import '../typography/tio_font_size.dart';
import '../typography/tio_letter_spacing.dart';
import 'tio_wheel_picker_tokens.dart';

class TioDobPickerTokens {
  const TioDobPickerTokens._();

  static const sheetOutlineAlpha = TioAlpha.alpha25;
  static const titleFontSize = TioFontSize.size22;
  static const titleLetterSpacing = TioLetterSpacing.negative02;
  static const closeIconSize = 24.0;
  static const closeSplashRadius = 20.0;
  static const headerSubtitleGap = 6.0;
  static const subtitleFontSize = TioFontSize.size14;
  static const columnHeaderFontSize = TioFontSize.size17;
  static const columnHeaderToWheelGap = TioSpacing.medium;
  static const wheelHeight = TioWheelPickerTokens.viewportHeight;
  static const selectionHeight = TioWheelPickerTokens.selectionHeight;
  static const selectionHorizontalMargin =
      TioWheelPickerTokens.selectionHorizontalMargin;
  static const selectionSurfaceAlpha = TioWheelPickerTokens.selectionSurfaceAlpha;
  static const itemExtent = TioWheelPickerTokens.itemExtent;
  static const perspective = 0.004;
  static const diameterRatio = 1.3;
  static const selectedFontSize = TioWheelPickerTokens.selectedFontSize;
  static const unselectedFontSize = TioFontSize.size17;
  static const unselectedTextAlpha = TioAlpha.alpha120;
}

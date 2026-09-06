import '../foundation/tio_spacing.dart';
import '../primitive/tio_alpha.dart';
import '../primitive/tio_size.dart';
import '../typography/tio_font_size.dart';

/// Cross-picker visual contracts proven identical across reusable DOB and
/// Product Onboarding drum-wheel implementations.
///
/// Drum curvature ([perspective] / [diameterRatio]) is part of this shared
/// contract: the DOB, weight, and height wheels were unified on the tighter
/// DOB curve after physical-device review, so a new picker cannot silently
/// reintroduce a different drum feel.
///
/// Picker-specific unselected treatment and typography remain owned by their
/// specialized token families.
class TioWheelPickerTokens {
  const TioWheelPickerTokens._();

  static const viewportHeight = TioSize.dp200;
  static const selectionHeight = TioSize.dp48;
  static const selectionHorizontalMargin = TioSpacing.lg;
  static const selectionSurfaceAlpha = TioAlpha.alpha200;
  static const itemExtent = TioSize.dp44;
  static const selectedFontSize = TioFontSize.size22;
  static const perspective = 0.004;
  static const diameterRatio = 1.3;
}

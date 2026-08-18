import '../foundation/tio_spacing.dart';

/// Cross-picker visual contracts proven identical across reusable DOB and
/// Product Onboarding drum-wheel implementations.
///
/// Picker-specific perspective, diameter, unselected treatment and typography
/// remain owned by their specialized token families.
class TioWheelPickerTokens {
  const TioWheelPickerTokens._();

  static const viewportHeight = 200.0;
  static const selectionHeight = 48.0;
  static const selectionHorizontalMargin = TioSpacing.large;
  static const selectionSurfaceAlpha = 200;
  static const itemExtent = 44.0;
  static const selectedFontSize = 22.0;
}

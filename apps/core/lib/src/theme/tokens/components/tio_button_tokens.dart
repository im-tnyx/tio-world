import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';
import '../foundation/tio_stroke.dart';
import '../primitive/tio_opacity.dart';

class TioButtonTokens {
  const TioButtonTokens._();

  static const height = 46.0;
  static const minimumWidth = 0.0;
  static const radius = TioRadius.full;
  static const horizontalPadding = 20.0;
  static const contentGap = TioSpacing.small;
  static const loadingIndicatorSize = 18.0;
  static const loadingIndicatorStrokeWidth = TioStroke.width2;
  static const pressedStateOpacity = TioOpacity.opacity12;
  static const focusedStateOpacity = TioOpacity.opacity12;
  static const hoveredStateOpacity = TioOpacity.opacity08;
  static const disabledContainerOpacity = TioOpacity.opacity12;
  static const disabledContentOpacity = TioOpacity.opacity38;
  static const outlineWidth = TioStroke.width1;
  static const focusedOutlineWidth = TioStroke.width2;
}

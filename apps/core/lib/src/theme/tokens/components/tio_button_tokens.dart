import '../foundation/tio_radius.dart';
import '../foundation/tio_spacing.dart';
import '../foundation/tio_stroke.dart';
import '../primitive/tio_opacity.dart';
import '../primitive/tio_size.dart';

class TioButtonTokens {
  const TioButtonTokens._();

  static const height = TioSize.dp46;
  static const minimumWidth = TioSize.dp0;
  static const radius = TioRadius.full;
  static const horizontalPadding = TioSize.dp20;
  static const contentGap = TioSpacing.sm;
  static const loadingIndicatorSize = TioSize.dp18;
  static const loadingIndicatorStrokeWidth = TioStroke.width2;
  static const pressedStateOpacity = TioOpacity.opacity12;
  static const focusedStateOpacity = TioOpacity.opacity12;
  static const hoveredStateOpacity = TioOpacity.opacity08;
  static const disabledContainerOpacity = TioOpacity.opacity12;
  static const disabledContentOpacity = TioOpacity.opacity38;
  static const outlineWidth = TioStroke.width1;
  static const focusedOutlineWidth = TioStroke.width2;
}

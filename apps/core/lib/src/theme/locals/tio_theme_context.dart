import 'package:flutter/material.dart';

import '../tokens/effects/tio_shadows.dart';
import '../tokens/foundation/tio_radius.dart';
import '../tokens/foundation/tio_spacing.dart';
import '../tokens/semantic/tio_colors.dart';

extension TioThemeContext on BuildContext {
  TioColors get tioColors {
    return Theme.of(this).extension<TioColors>() ?? TioColors.light;
  }

  TioShadows get tioShadows {
    return Theme.of(this).extension<TioShadows>() ?? TioShadows.standard;
  }

  double get spaceSmall => TioSpacing.small;
  double get spaceMedium => TioSpacing.medium;
  double get spaceLarge => TioSpacing.large;
  double get radiusSmall => TioRadius.small;
  double get radiusMedium => TioRadius.medium;
  double get radiusLarge => TioRadius.large;
}

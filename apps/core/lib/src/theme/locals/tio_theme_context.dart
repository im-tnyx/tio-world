import 'package:flutter/material.dart';

import '../tokens/effects/tio_motion_scheme.dart';
import '../tokens/effects/tio_shadows.dart';
import '../tokens/foundation/tio_radius.dart';
import '../tokens/semantic/tio_colors.dart';

extension TioThemeContext on BuildContext {
  TioColors get tioColors {
    return Theme.of(this).extension<TioColors>() ?? TioColors.light;
  }

  TioShadows get tioShadows {
    return Theme.of(this).extension<TioShadows>() ?? TioShadows.standard;
  }

  TioMotionScheme get tioMotion {
    return Theme.of(this).extension<TioMotionScheme>() ??
        const TioMotionScheme.standard();
  }

  // Compatibility accessors for existing feature consumers. Migrate these
  // call sites to TioRadius in their focused feature token slices.
  double get radiusSmall => TioRadius.small;
  double get radiusMedium => TioRadius.medium;
  double get radiusLarge => TioRadius.large;
}

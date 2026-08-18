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
    return Theme.of(this).extension<TioShadows>() ?? TioShadows.light;
  }

  TioMotionScheme get tioMotion {
    return Theme.of(this).extension<TioMotionScheme>() ??
        const TioMotionScheme.standard();
  }

  // Compatibility accessors for existing feature consumers. Migrate these
  // call sites to canonical TioRadius roles in their focused feature slices.
  // The compatibility API stays pixel-equivalent while its implementation
  // resolves through the canonical radius names.
  double get radiusSmall => TioRadius.sm;
  double get radiusMedium => TioRadius.md;
  double get radiusLarge => TioRadius.lg;
}

import 'package:flutter/material.dart';

import '../tio_colors.dart';
import '../tio_radius.dart';
import '../tio_shadows.dart';
import '../tio_spacing.dart';

extension TioThemeContext on BuildContext {
  TioColors get tioColors {
    return Theme.of(this).extension<TioColors>() ?? TioColors.light;
  }

  TioShadows get tioShadows {
    return Theme.of(this).extension<TioShadows>() ?? TioShadows.standard;
  }

  TioSpacing get tioSpacing => TioSpacing.standard;
  TioRadius get tioRadius => TioRadius.standard;
}

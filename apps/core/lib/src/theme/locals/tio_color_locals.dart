import 'package:flutter/material.dart';

import '../tokens/semantic/tio_colors.dart';

extension TioColorLocals on BuildContext {
  TioColors get localTioColors {
    return Theme.of(this).extension<TioColors>() ?? TioColors.light;
  }
}

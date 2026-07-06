import 'package:flutter/material.dart';

import '../tokens/effects/tio_shadows.dart';

class TioShadowsLocals {
  const TioShadowsLocals._();

  static TioShadows of(BuildContext context) {
    return Theme.of(context).extension<TioShadows>() ?? TioShadows.standard;
  }
}

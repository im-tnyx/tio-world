import 'package:flutter/material.dart';

import '../foundation/tio_palette.dart';
import '../primitive/tio_size.dart';

/// Reusable static shadow contracts.
///
/// This class owns the canonical shadow composition. Runtime theme extensions
/// such as [TioShadows] must alias these contracts instead of redefining the
/// same physical values independently.
class TioShadowTokens {
  const TioShadowTokens._();

  static const softBlurRadius = TioSize.dp24;
  static const softOffset = Offset(TioSize.dp0, TioSize.dp12);
  static const softColor = TioPalette.blackAlpha26;

  static const soft = [
    BoxShadow(
      blurRadius: softBlurRadius,
      offset: softOffset,
      color: softColor,
    ),
  ];
}

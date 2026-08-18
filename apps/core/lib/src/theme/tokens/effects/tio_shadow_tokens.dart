import 'package:flutter/material.dart';

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

  // Keep the exact existing shadow color until the Slice A color ownership
  // audit decides its final palette/effect owner.
  static const softColor = Color(0x1A000000);

  static const soft = [
    BoxShadow(
      blurRadius: softBlurRadius,
      offset: softOffset,
      color: softColor,
    ),
  ];
}

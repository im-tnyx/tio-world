import 'dart:math' as math;

import 'package:flutter/services.dart';

enum WearDisplayShape {
  rectangular,
  round,
}

abstract interface class WearDisplayShapeReader {
  Future<WearDisplayShape> read();
}

class MethodChannelWearDisplayShapeReader implements WearDisplayShapeReader {
  const MethodChannelWearDisplayShapeReader();

  static const _channel = MethodChannel('com.tnyx.wear/device');

  @override
  Future<WearDisplayShape> read() async {
    try {
      final isRound = await _channel.invokeMethod<bool>('isScreenRound') ?? false;
      return isRound ? WearDisplayShape.round : WearDisplayShape.rectangular;
    } on MissingPluginException {
      return WearDisplayShape.rectangular;
    } on PlatformException {
      return WearDisplayShape.rectangular;
    }
  }
}

double wearHorizontalSafeInset({
  required double shortestSide,
  required WearDisplayShape shape,
  required double baselineInset,
}) {
  if (shape != WearDisplayShape.round || shortestSide <= 0) {
    return baselineInset;
  }

  // Keep rectangular list content inside the largest axis-aligned square that
  // fits within the circular display. The inset from the circle's bounding box
  // to that square is D * (1 - 1/sqrt(2)) / 2 on each side.
  final circularInset = shortestSide * (1 - 1 / math.sqrt(2)) / 2;
  return math.max(baselineInset, circularInset);
}

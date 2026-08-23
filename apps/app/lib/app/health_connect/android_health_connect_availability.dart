import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum HealthConnectPlatformPresence {
  absent,
  present,
}

/// Thin app-owned bridge to Android Health Connect platform surface presence.
///
/// This probe does not prove Health Connect SDK readiness, does not request
/// health-data permissions, and does not imply authorization to read or write
/// any health record type.
class AndroidHealthConnectSurfaceProbe {
  AndroidHealthConnectSurfaceProbe({
    MethodChannel? channel,
    bool Function()? isAndroidPlatform,
  })  : _channel = channel ?? const MethodChannel(channelName),
        _isAndroidPlatform = isAndroidPlatform ?? _defaultIsAndroidPlatform;

  static const channelName = 'com.tnyx.tio/health_connect_availability';
  static const _getAvailabilityMethod = 'getAvailability';

  final MethodChannel _channel;
  final bool Function() _isAndroidPlatform;

  Future<HealthConnectPlatformPresence> read() async {
    if (!_isAndroidPlatform()) {
      return HealthConnectPlatformPresence.absent;
    }

    try {
      final raw = await _channel.invokeMethod<String>(_getAvailabilityMethod);
      return raw == 'present'
          ? HealthConnectPlatformPresence.present
          : HealthConnectPlatformPresence.absent;
    } catch (_) {
      // Surface presence is advisory platform state. Any channel/platform
      // failure must fail closed and must never be interpreted as readiness or
      // authorization.
      return HealthConnectPlatformPresence.absent;
    }
  }

  static bool _defaultIsAndroidPlatform() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }
}

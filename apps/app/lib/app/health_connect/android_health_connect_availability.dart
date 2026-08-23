import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

enum HealthConnectPlatformAvailability {
  unavailable,
  available,
}

/// Thin app-owned bridge to Android Health Connect platform availability.
///
/// This probe does not request health-data permissions and does not imply that
/// the app is authorized to read or write any health record type.
class AndroidHealthConnectAvailabilityProbe {
  AndroidHealthConnectAvailabilityProbe({
    MethodChannel? channel,
    bool Function()? isAndroidPlatform,
  })  : _channel = channel ?? const MethodChannel(channelName),
        _isAndroidPlatform =
            isAndroidPlatform ?? _defaultIsAndroidPlatform;

  static const channelName = 'com.tnyx.tio/health_connect_availability';
  static const _getAvailabilityMethod = 'getAvailability';

  final MethodChannel _channel;
  final bool Function() _isAndroidPlatform;

  Future<HealthConnectPlatformAvailability> read() async {
    if (!_isAndroidPlatform()) {
      return HealthConnectPlatformAvailability.unavailable;
    }

    try {
      final raw = await _channel.invokeMethod<String>(_getAvailabilityMethod);
      return raw == 'available'
          ? HealthConnectPlatformAvailability.available
          : HealthConnectPlatformAvailability.unavailable;
    } catch (_) {
      // Availability is advisory platform state. Any channel/platform failure
      // must fail closed and must never be interpreted as authorization.
      return HealthConnectPlatformAvailability.unavailable;
    }
  }

  static bool _defaultIsAndroidPlatform() {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }
}

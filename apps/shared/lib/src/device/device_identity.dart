/// Immutable device identity snapshot used for authenticated backend requests.
class DeviceIdentity {
  const DeviceIdentity({
    required this.deviceId,
    required this.deviceFingerprint,
    this.platform,
    this.osVersion,
    this.appVersion,
    this.appBuild,
    this.fcmToken,
  });

  final String deviceId;
  final String deviceFingerprint;
  final String? platform;
  final String? osVersion;
  final String? appVersion;
  final int? appBuild;
  final String? fcmToken;
}

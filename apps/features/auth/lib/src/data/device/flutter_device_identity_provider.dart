import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

class FlutterDeviceIdentityProvider implements DeviceIdentityProvider {
  FlutterDeviceIdentityProvider({
    DeviceInfoPlugin? deviceInfoPlugin,
    Future<PackageInfo> Function()? packageInfoLoader,
    SharedPreferences? sharedPreferences,
  })  : _deviceInfoPlugin = deviceInfoPlugin,
        _packageInfoLoader = packageInfoLoader,
        _sharedPreferences = sharedPreferences;

  static const _deviceIdKey = 'tio_device_id';
  final DeviceInfoPlugin? _deviceInfoPlugin;
  final Future<PackageInfo> Function()? _packageInfoLoader;
  final SharedPreferences? _sharedPreferences;
  DeviceIdentity? _cached;

  @override
  Future<DeviceIdentity> getIdentity() async {
    if (_cached != null) return _cached!;

    final prefs = _sharedPreferences ?? await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }

    final deviceInfo = _deviceInfoPlugin ?? DeviceInfoPlugin();
    String? osVersion;
    String? deviceModel;
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
            ? 'ios'
            : 'unknown';

    try {
      if (Platform.isAndroid) {
        final info = await deviceInfo.androidInfo;
        osVersion = info.version.release;
        deviceModel = info.model;
      } else if (Platform.isIOS) {
        final info = await deviceInfo.iosInfo;
        osVersion = info.systemVersion;
        deviceModel = info.model;
      }
    } catch (_) {}

    String? appVersion;
    int? appBuild;
    try {
      final pkgInfo = _packageInfoLoader != null
          ? await _packageInfoLoader()
          : await PackageInfo.fromPlatform();
      final version = pkgInfo.version.trim();
      if (version.isNotEmpty) {
        appVersion = version;
      }
      final rawBuild = pkgInfo.buildNumber.trim();
      if (rawBuild.isNotEmpty) {
        appBuild = int.tryParse(rawBuild);
      }
    } catch (_) {}

    final rawFingerprint =
        '$deviceId|$platform|${deviceModel ?? ''}|${osVersion ?? ''}';
    final fingerprintBytes = utf8.encode(rawFingerprint);
    final digest = sha256.convert(fingerprintBytes);
    final deviceFingerprint = digest.toString();

    _cached = DeviceIdentity(
      deviceId: deviceId,
      deviceFingerprint: deviceFingerprint,
      platform: platform,
      osVersion: osVersion,
      appVersion: appVersion,
      appBuild: appBuild,
    );
    return _cached!;
  }
}

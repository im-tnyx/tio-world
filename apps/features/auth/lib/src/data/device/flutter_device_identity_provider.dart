import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_shared/shared.dart';
import 'package:uuid/uuid.dart';

class FlutterDeviceIdentityProvider implements DeviceIdentityProvider {
  static const _deviceIdKey = 'tio_device_id';
  DeviceIdentity? _cached;

  @override
  Future<DeviceIdentity> getIdentity() async {
    if (_cached != null) return _cached!;
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString(_deviceIdKey);
    if (deviceId == null || deviceId.isEmpty) {
      deviceId = const Uuid().v4();
      await prefs.setString(_deviceIdKey, deviceId);
    }
    final deviceInfo = DeviceInfoPlugin();
    String? osVersion;
    String? deviceModel;
    final platform = Platform.isAndroid ? 'android' : Platform.isIOS ? 'ios' : 'unknown';
    if (Platform.isAndroid) {
      final info = await deviceInfo.androidInfo;
      osVersion = info.version.release;
      deviceModel = info.model;
    } else if (Platform.isIOS) {
      final info = await deviceInfo.iosInfo;
      osVersion = info.systemVersion;
      deviceModel = info.model;
    }
    final rawFingerprint = '$deviceId|$platform|${deviceModel ?? ''}|${osVersion ?? ''}';
    final fingerprintBytes = utf8.encode(rawFingerprint);
    final digest = sha256.convert(fingerprintBytes);
    final deviceFingerprint = digest.toString();
    _cached = DeviceIdentity(
      deviceId: deviceId,
      deviceFingerprint: deviceFingerprint,
      platform: platform,
      osVersion: osVersion,
    );
    return _cached!;
  }
}

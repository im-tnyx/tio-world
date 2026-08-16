import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tio_feature_auth/src/data/device/flutter_device_identity_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterDeviceIdentityProvider', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('maps version and numeric build number accurately from PackageInfo',
        () async {
      final provider = FlutterDeviceIdentityProvider(
        packageInfoLoader: () async => PackageInfo(
          appName: 'Tio',
          packageName: 'com.tnyx.tio',
          version: '1.2.3',
          buildNumber: '42',
        ),
      );

      final identity = await provider.getIdentity();
      expect(identity.appVersion, '1.2.3');
      expect(identity.appBuild, 42);
      expect(identity.deviceId, isNotEmpty);
      expect(identity.deviceFingerprint, isNotEmpty);
    });

    test('does not fabricate build number when buildNumber is empty or non-numeric',
        () async {
      final providerEmpty = FlutterDeviceIdentityProvider(
        packageInfoLoader: () async => PackageInfo(
          appName: 'Tio',
          packageName: 'com.tnyx.tio',
          version: '2.0.0',
          buildNumber: '',
        ),
      );

      final identityEmpty = await providerEmpty.getIdentity();
      expect(identityEmpty.appVersion, '2.0.0');
      expect(identityEmpty.appBuild, isNull);

      final providerNonNumeric = FlutterDeviceIdentityProvider(
        packageInfoLoader: () async => PackageInfo(
          appName: 'Tio',
          packageName: 'com.tnyx.tio',
          version: '2.0.0',
          buildNumber: 'beta-3',
        ),
      );

      final identityNonNumeric = await providerNonNumeric.getIdentity();
      expect(identityNonNumeric.appVersion, '2.0.0');
      expect(identityNonNumeric.appBuild, isNull);
    });

    test('caches identity snapshot across repeated invocations', () async {
      int callCount = 0;
      final provider = FlutterDeviceIdentityProvider(
        packageInfoLoader: () async {
          callCount++;
          return PackageInfo(
            appName: 'Tio',
            packageName: 'com.tnyx.tio',
            version: '1.0.0',
            buildNumber: '1',
          );
        },
      );

      final identity1 = await provider.getIdentity();
      final identity2 = await provider.getIdentity();

      expect(callCount, 1);
      expect(identity1.deviceId, identity2.deviceId);
      expect(identity1.appVersion, identity2.appVersion);
      expect(identity1.appBuild, identity2.appBuild);
    });

    test('handles package info loader failure gracefully without crashing',
        () async {
      final provider = FlutterDeviceIdentityProvider(
        packageInfoLoader: () async => throw Exception('Platform channel error'),
      );

      final identity = await provider.getIdentity();
      expect(identity.deviceId, isNotEmpty);
      expect(identity.appVersion, isNull);
      expect(identity.appBuild, isNull);
    });
  });
}

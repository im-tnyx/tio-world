import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/health_connect/android_health_connect_availability.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    AndroidHealthConnectSurfaceProbe.channelName,
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('exact native present result maps to platform surface present', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getAvailability');
      return 'present';
    });
    final probe = AndroidHealthConnectSurfaceProbe(
      channel: channel,
      isAndroidPlatform: () => true,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformPresence.present,
    );
  });

  test('native absent result fails closed', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'absent');
    final probe = AndroidHealthConnectSurfaceProbe(
      channel: channel,
      isAndroidPlatform: () => true,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformPresence.absent,
    );
  });

  test('unknown native result never becomes surface present', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'unexpected');
    final probe = AndroidHealthConnectSurfaceProbe(
      channel: channel,
      isAndroidPlatform: () => true,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformPresence.absent,
    );
  });

  test('platform-channel failure never becomes surface present', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'health-connect-unavailable');
    });
    final probe = AndroidHealthConnectSurfaceProbe(
      channel: channel,
      isAndroidPlatform: () => true,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformPresence.absent,
    );
  });

  test('non-Android platform does not invoke native channel', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      nativeCalls++;
      return 'present';
    });
    final probe = AndroidHealthConnectSurfaceProbe(
      channel: channel,
      isAndroidPlatform: () => false,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformPresence.absent,
    );
    expect(nativeCalls, 0);
  });
}

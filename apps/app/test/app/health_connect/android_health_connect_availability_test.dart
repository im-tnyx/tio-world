import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/health_connect/android_health_connect_availability.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(
    AndroidHealthConnectAvailabilityProbe.channelName,
  );
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() async {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('exact native available result maps to platform available', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getAvailability');
      return 'available';
    });
    final probe = AndroidHealthConnectAvailabilityProbe(
      channel: channel,
      isAndroidPlatform: () => true,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformAvailability.available,
    );
  });

  test('native unavailable result fails closed', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'unavailable');
    final probe = AndroidHealthConnectAvailabilityProbe(
      channel: channel,
      isAndroidPlatform: () => true,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformAvailability.unavailable,
    );
  });

  test('unknown native result never becomes available', () async {
    messenger.setMockMethodCallHandler(channel, (_) async => 'unexpected');
    final probe = AndroidHealthConnectAvailabilityProbe(
      channel: channel,
      isAndroidPlatform: () => true,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformAvailability.unavailable,
    );
  });

  test('platform-channel failure never becomes available', () async {
    messenger.setMockMethodCallHandler(channel, (_) async {
      throw PlatformException(code: 'health-connect-unavailable');
    });
    final probe = AndroidHealthConnectAvailabilityProbe(
      channel: channel,
      isAndroidPlatform: () => true,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformAvailability.unavailable,
    );
  });

  test('non-Android platform does not invoke native channel', () async {
    var nativeCalls = 0;
    messenger.setMockMethodCallHandler(channel, (_) async {
      nativeCalls++;
      return 'available';
    });
    final probe = AndroidHealthConnectAvailabilityProbe(
      channel: channel,
      isAndroidPlatform: () => false,
    );

    expect(
      await probe.read(),
      HealthConnectPlatformAvailability.unavailable,
    );
    expect(nativeCalls, 0);
  });
}

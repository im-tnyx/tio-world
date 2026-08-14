import 'device_identity.dart';

/// Contract for providing stable device identity across sessions.
abstract interface class DeviceIdentityProvider {
  Future<DeviceIdentity> getIdentity();
}

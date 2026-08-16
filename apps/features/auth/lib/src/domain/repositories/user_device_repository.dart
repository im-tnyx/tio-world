abstract class UserDeviceRepository {
  /// Syncs the current client device identity with the authenticated user record.
  Future<void> syncCurrentDevice();
}

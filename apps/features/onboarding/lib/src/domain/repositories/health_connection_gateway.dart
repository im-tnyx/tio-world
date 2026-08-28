import '../models/health_connection_status.dart';

/// Platform-neutral boundary for live health connection capability and
/// authorization truth.
///
/// Product Onboarding never owns imported health records through this contract.
abstract interface class HealthConnectionGateway {
  Future<HealthConnectionStatus> readStatus();

  /// Must only be called after an explicit user action.
  Future<HealthConnectionStatus> requestConnection();
}

/// O7B fail-safe implementation used until a real platform adapter is wired.
///
/// It performs no OS permission request and can never fabricate a connected
/// state.
class UnavailableHealthConnectionGateway implements HealthConnectionGateway {
  const UnavailableHealthConnectionGateway();

  @override
  Future<HealthConnectionStatus> readStatus() async =>
      HealthConnectionStatus.unavailable;

  @override
  Future<HealthConnectionStatus> requestConnection() async =>
      HealthConnectionStatus.unavailable;
}

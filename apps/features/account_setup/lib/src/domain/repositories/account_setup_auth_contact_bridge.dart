/// App-composed bridge from Account Setup to trusted Auth contact evidence.
///
/// The Account Setup feature must not own provider SDK logic. Production app
/// composition can implement this narrow capability alongside
/// `AccountSetupRepository` so the flow can plan complementary contacts and
/// request optional Email confirmation without importing the Auth feature.
abstract interface class AccountSetupAuthContactBridge {
  bool get hasTrustedEmailIdentity;

  bool get hasTrustedPhoneIdentity;

  String get currentEmail;

  Future<void> requestOptionalEmailVerification(String email);
}

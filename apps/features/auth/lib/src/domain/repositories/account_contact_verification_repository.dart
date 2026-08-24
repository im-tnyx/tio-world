/// Auth-owned boundary for verifying Account contact identifiers.
///
/// Implementations must use the configured authentication provider as the
/// ownership proof. Application/profile rows and client booleans are never
/// verification authority.
abstract interface class AccountContactVerificationRepository {
  /// Re-sends confirmation for the current authenticated, unverified email.
  Future<void> requestCurrentEmailVerification(String email);

  /// Confirms the current authenticated email using the provider-issued code.
  Future<void> verifyCurrentEmail({
    required String email,
    required String token,
  });

  /// Starts add/change verification for a phone number.
  Future<void> requestPhoneVerification(String phoneNumber);

  /// Confirms a pending phone add/change using the provider-issued code.
  Future<void> verifyPhoneChange({
    required String phoneNumber,
    required String token,
  });
}

/// Auth-owned boundary for verifying Account contact identifiers.
///
/// Implementations must use the configured authentication provider as the
/// ownership proof. Application/profile rows and client booleans are never
/// verification authority.
abstract interface class AccountContactVerificationRepository {
  /// Starts verification for an existing unverified Email or an Email add/change.
  Future<void> requestEmailVerification(String email);

  /// Confirms the pending Email verification using the provider-issued code.
  Future<void> verifyEmail({
    required String email,
    required String token,
  });

  /// Compatibility aliases for existing Account Settings composition.
  ///
  /// Despite the historical names, implementations must support both the
  /// current Email and a pending Email add/change through the same trusted Auth
  /// provider flow. These are not separate verification authorities.
  Future<void> requestCurrentEmailVerification(String email);

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

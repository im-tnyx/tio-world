/// Repository boundary for account fields owned by Account Settings.
abstract interface class ProfileAccountRepository {
  /// Updates the current authenticated user's username and mobile number.
  ///
  /// Implementations must preserve profile fields outside Account Settings
  /// ownership and must not create or switch authentication identities.
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  });
}

/// Raised when a username loses an availability race before persistence.
class UsernameUnavailableException implements Exception {
  const UsernameUnavailableException();

  @override
  String toString() => 'UsernameUnavailableException';
}

/// Repository boundary for account fields owned by Account Settings and
/// authenticated account bootstrap.
abstract interface class ProfileAccountRepository {
  /// Checks whether [username] is available for the current authenticated user.
  ///
  /// Implementations must not expose other users' profile rows while answering
  /// this question.
  Future<bool> isUsernameAvailable(String username);

  /// Updates only the current authenticated user's username.
  ///
  /// Implementations must preserve display name, mobile, and every other
  /// profile field. Database uniqueness remains the final authority even after
  /// a successful availability pre-check.
  Future<void> updateUsername(String username);

  /// Updates the current authenticated user's username and mobile number.
  ///
  /// Implementations must preserve profile fields outside Account Settings
  /// ownership and must not create or switch authentication identities.
  Future<void> updateAccountSettings({
    required String username,
    required String mobile,
  });
}

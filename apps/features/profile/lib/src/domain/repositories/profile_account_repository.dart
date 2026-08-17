enum UsernameAvailabilityReason {
  taken,
  invalid,
  reserved,
  profileMissing,
  unknown,
}

class UsernameAvailabilityCheck {
  const UsernameAvailabilityCheck({
    required this.normalized,
    required this.isAvailable,
    this.suggestions = const [],
    this.reason,
  });

  final String normalized;
  final bool isAvailable;
  final List<String> suggestions;
  final UsernameAvailabilityReason? reason;
}

/// Raised when a username cannot be persisted under the canonical server
/// policy, including a final database uniqueness race.
class UsernameUnavailableException implements Exception {
  const UsernameUnavailableException({
    this.reason,
    this.suggestions = const [],
  });

  final UsernameAvailabilityReason? reason;
  final List<String> suggestions;

  @override
  String toString() => 'UsernameUnavailableException';
}

/// Repository boundary for account fields owned by Account Settings and
/// authenticated account bootstrap.
abstract interface class ProfileAccountRepository {
  /// Returns the current authenticated user's normalized username, or null when
  /// the local profile is missing or the username has not been chosen yet.
  Future<String?> currentUsername();

  /// Returns the server-owned availability decision and verified alternatives.
  ///
  /// Implementations must not expose other users' profile rows while answering
  /// this question.
  Future<UsernameAvailabilityCheck> checkUsernameAvailability(String username);

  /// Compatibility convenience for callers that only need the boolean answer.
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

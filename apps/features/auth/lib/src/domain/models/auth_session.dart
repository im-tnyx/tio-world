/// Domain model representing an authenticated user session.
/// Keeps raw authentication SDK user types decoupled from application logic.
class AuthSession {
  const AuthSession({
    required this.userId,
    this.email,
    this.phone,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.displayName,
    this.photoUrl,
    this.loginCycleId,
  });

  final String userId;
  final String? email;
  final String? phone;
  final bool isEmailVerified;
  final bool isPhoneVerified;
  final String? displayName;
  final String? photoUrl;

  /// Provider-neutral identifier for the current real sign-in cycle.
  ///
  /// Adapters should keep this stable across token refreshes and change it after
  /// a new interactive sign-in whenever their SDK exposes that information.
  final String? loginCycleId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSession &&
        other.userId == userId &&
        other.email == email &&
        other.phone == phone &&
        other.isEmailVerified == isEmailVerified &&
        other.isPhoneVerified == isPhoneVerified &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl &&
        other.loginCycleId == loginCycleId;
  }

  @override
  int get hashCode => Object.hash(
        userId,
        email,
        phone,
        isEmailVerified,
        isPhoneVerified,
        displayName,
        photoUrl,
        loginCycleId,
      );

  @override
  String toString() =>
      'AuthSession(userId: $userId, email: $email, phone: $phone)';
}

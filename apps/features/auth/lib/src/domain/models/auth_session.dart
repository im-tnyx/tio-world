/// Domain model representing an authenticated user session.
/// Keeps raw authentication SDK user types decoupled from application logic.
class AuthSession {
  const AuthSession({
    required this.userId,
    this.email,
    this.phone,
    this.isEmailVerified = false,
    this.isPhoneVerified = false,
    this.identityProviders = const <String>{},
    this.displayName,
    this.photoUrl,
    this.loginCycleId,
  });

  final String userId;
  final String? email;
  final String? phone;
  final bool isEmailVerified;
  final bool isPhoneVerified;

  /// Trusted authentication identities reported by the Auth provider.
  ///
  /// Values are normalized lowercase provider names such as `phone`, `email`,
  /// and `google`. UI must use this evidence instead of inferring a provider
  /// from contact presence or hardcoding a provider label.
  final Set<String> identityProviders;

  final String? displayName;
  final String? photoUrl;

  /// Provider-neutral identifier for the current real sign-in cycle.
  ///
  /// Adapters should keep this stable across token refreshes and change it after
  /// a new interactive sign-in whenever their SDK exposes that information.
  final String? loginCycleId;

  bool _hasSameIdentityProviders(AuthSession other) {
    return identityProviders.length == other.identityProviders.length &&
        identityProviders.containsAll(other.identityProviders);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSession &&
        other.userId == userId &&
        other.email == email &&
        other.phone == phone &&
        other.isEmailVerified == isEmailVerified &&
        other.isPhoneVerified == isPhoneVerified &&
        _hasSameIdentityProviders(other) &&
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
        Object.hashAllUnordered(identityProviders),
        displayName,
        photoUrl,
        loginCycleId,
      );

  @override
  String toString() =>
      'AuthSession(userId: $userId, email: $email, phone: $phone, identityProviders: $identityProviders)';
}

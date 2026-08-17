/// Domain model representing an authenticated user session.
/// Keeps raw Firebase SDK user types decoupled from application logic.
class AuthSession {
  const AuthSession({
    required this.userId,
    this.email,
    this.phone,
    this.displayName,
    this.photoUrl,
  });

  final String userId;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? photoUrl;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSession &&
        other.userId == userId &&
        other.email == email &&
        other.phone == phone &&
        other.displayName == displayName &&
        other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => Object.hash(
        userId,
        email,
        phone,
        displayName,
        photoUrl,
      );

  @override
  String toString() => 'AuthSession(userId: $userId, email: $email, phone: $phone)';
}

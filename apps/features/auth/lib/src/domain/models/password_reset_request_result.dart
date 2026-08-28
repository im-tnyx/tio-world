/// Result of requesting a password-recovery email.
///
/// This contract is intentionally separate from sign-in results because a
/// successful request does not establish an authenticated session and does not
/// prove that an account exists for the supplied email address.
sealed class PasswordResetRequestResult {
  const PasswordResetRequestResult();
}

/// The auth provider accepted the recovery request.
///
/// This does not prove account existence or guaranteed email delivery.
class PasswordResetRequestAccepted extends PasswordResetRequestResult {
  const PasswordResetRequestAccepted();

  @override
  bool operator ==(Object other) => other is PasswordResetRequestAccepted;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'PasswordResetRequestAccepted()';
}

/// The password-reset request failed before it could be accepted.
class PasswordResetRequestFailure extends PasswordResetRequestResult {
  const PasswordResetRequestFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  bool operator ==(Object other) =>
      other is PasswordResetRequestFailure &&
      other.message == message &&
      other.code == code;

  @override
  int get hashCode => Object.hash(message, code);

  @override
  String toString() =>
      'PasswordResetRequestFailure($message, code: $code)';
}

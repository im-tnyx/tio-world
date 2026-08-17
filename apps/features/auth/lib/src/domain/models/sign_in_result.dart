import 'auth_session.dart';

/// Sealed hierarchy representing the result of an authentication sign-in attempt.
sealed class SignInResult {
  const SignInResult();
}

/// Sign-in completed successfully and established an authenticated [session].
class SignInSuccess extends SignInResult {
  const SignInSuccess(this.session);
  final AuthSession session;

  @override
  bool operator ==(Object other) => other is SignInSuccess && other.session == session;
  @override
  int get hashCode => session.hashCode;
  @override
  String toString() => 'SignInSuccess(session: $session)';
}

/// Sign-in was dismissed/cancelled by the user.
class SignInCancelled extends SignInResult {
  const SignInCancelled();

  @override
  bool operator ==(Object other) => other is SignInCancelled;
  @override
  int get hashCode => runtimeType.hashCode;
  @override
  String toString() => 'SignInCancelled()';
}

/// Sign-in failed with a typed user-facing [message].
class SignInFailure extends SignInResult {
  const SignInFailure(this.message, {this.code});
  final String message;
  final String? code;

  @override
  bool operator ==(Object other) =>
      other is SignInFailure && other.message == message && other.code == code;
  @override
  int get hashCode => Object.hash(message, code);
  @override
  String toString() => 'SignInFailure($message, code: $code)';
}

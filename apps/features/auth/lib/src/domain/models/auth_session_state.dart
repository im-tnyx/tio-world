import 'auth_session.dart';

/// Represents the current lifecycle state of user authentication.
sealed class AuthSessionState {
  const AuthSessionState();
}

/// Initial state during app startup before session check resolves.
class AuthSessionUnknown extends AuthSessionState {
  const AuthSessionUnknown();

  @override
  bool operator ==(Object other) => other is AuthSessionUnknown;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthSessionUnknown()';
}

/// User is definitely signed out / unauthenticated.
class AuthSessionUnauthenticated extends AuthSessionState {
  const AuthSessionUnauthenticated();

  @override
  bool operator ==(Object other) => other is AuthSessionUnauthenticated;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AuthSessionUnauthenticated()';
}

/// User is authenticated with an active session.
class AuthSessionAuthenticated extends AuthSessionState {
  const AuthSessionAuthenticated(this.session);

  final AuthSession session;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthSessionAuthenticated && other.session == session;
  }

  @override
  int get hashCode => session.hashCode;

  @override
  String toString() => 'AuthSessionAuthenticated($session)';
}

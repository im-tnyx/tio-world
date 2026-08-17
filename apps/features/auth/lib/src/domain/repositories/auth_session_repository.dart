import '../models/auth_session_state.dart';

/// Contract for observing and managing the user authentication session.
abstract interface class AuthSessionRepository {
  /// Stream emitting real-time authentication state transitions.
  Stream<AuthSessionState> get sessionState;

  /// Retrieves the current snapshot of authentication state.
  Future<AuthSessionState> get currentSessionState;

  /// Signs the current user out of their session.
  Future<void> signOut();
}

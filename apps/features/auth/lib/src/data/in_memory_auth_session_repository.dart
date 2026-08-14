import 'dart:async';

import '../domain/domain.dart';

/// In-memory implementation of [AuthSessionRepository] for development, preview, and unit tests.
class InMemoryAuthSessionRepository implements AuthSessionRepository {
  InMemoryAuthSessionRepository({
    AuthSessionState initialSessionState = const AuthSessionUnauthenticated(),
  })  : _currentState = initialSessionState,
        _controller = StreamController<AuthSessionState>.broadcast() {
    _controller.add(initialSessionState);
  }

  AuthSessionState _currentState;
  final StreamController<AuthSessionState> _controller;

  @override
  Stream<AuthSessionState> get sessionState => _controller.stream;

  @override
  Future<AuthSessionState> get currentSessionState async => _currentState;

  /// Sets the session for testing / dev state manipulation.
  void setSession(AuthSession? session) {
    if (session != null) {
      _currentState = AuthSessionAuthenticated(session);
    } else {
      _currentState = const AuthSessionUnauthenticated();
    }
    _controller.add(_currentState);
  }

  @override
  Future<void> signOut() async {
    _currentState = const AuthSessionUnauthenticated();
    _controller.add(_currentState);
  }

  void dispose() {
    _controller.close();
  }
}

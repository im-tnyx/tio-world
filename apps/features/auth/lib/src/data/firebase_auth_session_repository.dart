import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../domain/models/auth_session.dart';
import '../domain/models/auth_session_state.dart';
import '../domain/repositories/auth_session_repository.dart';

/// Concrete [AuthSessionRepository] backed by [fb.FirebaseAuth].
/// Observes Firebase Auth state changes and maps Firebase User to domain [AuthSession].
class FirebaseAuthSessionRepository implements AuthSessionRepository {
  FirebaseAuthSessionRepository({
    fb.FirebaseAuth? auth,
    Stream<fb.User?>? authStateStream,
    fb.User? Function()? currentUserGetter,
    Future<void> Function()? signOutHandler,
  })  : _auth = auth,
        _authStateStream = authStateStream,
        _currentUserGetter = currentUserGetter,
        _signOutHandler = signOutHandler;

  final fb.FirebaseAuth? _auth;
  final Stream<fb.User?>? _authStateStream;
  final fb.User? Function()? _currentUserGetter;
  final Future<void> Function()? _signOutHandler;

  fb.FirebaseAuth get _firebaseAuth => _auth ?? fb.FirebaseAuth.instance;

  @override
  Stream<AuthSessionState> get sessionState {
    final stream = _authStateStream ?? _firebaseAuth.authStateChanges();
    return stream.map(_mapFirebaseUserToSessionState);
  }

  @override
  Future<AuthSessionState> get currentSessionState async {
    final user = _currentUserGetter != null
        ? _currentUserGetter()
        : _firebaseAuth.currentUser;
    return _mapFirebaseUserToSessionState(user);
  }

  @override
  Future<void> signOut() async {
    if (_signOutHandler != null) {
      await _signOutHandler();
      return;
    }
    await _firebaseAuth.signOut();
  }

  static AuthSessionState _mapFirebaseUserToSessionState(fb.User? user) {
    if (user == null) {
      return const AuthSessionUnauthenticated();
    }

    final session = AuthSession(
      userId: user.uid,
      email: user.email,
      phone: user.phoneNumber,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );

    return AuthSessionAuthenticated(session);
  }
}

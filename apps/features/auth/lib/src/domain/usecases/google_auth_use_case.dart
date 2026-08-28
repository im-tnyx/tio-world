import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/auth_session.dart';
import '../models/backend_user_state.dart';
import '../repositories/backend_user_sync_repository.dart';
import '../../data/google_sign_in_provider.dart';
import 'package:tio_shared/shared.dart';

/// Legacy Firebase-backed Google authentication compatibility path.
///
/// Production Tio authentication is Supabase-first. This use case therefore
/// fails closed unless a caller explicitly opts into the legacy Firebase path.
/// That prevents an unconfigured/debug Supabase composition from silently
/// falling back to `FirebaseAuth.instance` and surfacing `[core/no-app]` after
/// Google account selection.
class GoogleAuthUseCase {
  const GoogleAuthUseCase({
    required GoogleSignInProvider googleSignInProvider,
    required BackendUserSyncRepository backendUserSyncRepository,
    required DeviceIdentityProvider deviceIdentityProvider,
    fb.FirebaseAuth? firebaseAuth,
    bool legacyFirebaseEnabled = false,
  })  : _googleSignInProvider = googleSignInProvider,
        _backendUserSyncRepository = backendUserSyncRepository,
        _deviceIdentityProvider = deviceIdentityProvider,
        _firebaseAuth = firebaseAuth,
        _legacyFirebaseEnabled = legacyFirebaseEnabled;

  static const unavailableMessage =
      'Google sign-in is unavailable in this app build.';

  final GoogleSignInProvider _googleSignInProvider;
  final BackendUserSyncRepository _backendUserSyncRepository;
  final DeviceIdentityProvider _deviceIdentityProvider;
  final fb.FirebaseAuth? _firebaseAuth;
  final bool _legacyFirebaseEnabled;

  fb.FirebaseAuth get _auth => _firebaseAuth ?? fb.FirebaseAuth.instance;

  Future<GoogleAuthResult> call() async {
    if (!_legacyFirebaseEnabled) {
      return const GoogleAuthFailed(unavailableMessage);
    }

    // Step 1: Google Sign-In → Google ID Token
    final signInResult = await _googleSignInProvider.signIn();
    return switch (signInResult) {
      GoogleSignInCancelled() => const GoogleAuthCancelled(),
      GoogleSignInFailed(:final message) => GoogleAuthFailed(message),
      GoogleSignInSuccess(:final googleIdToken, :final displayName, :final photoUrl) =>
        await _continueWithCredential(
          googleIdToken: googleIdToken,
          displayName: displayName,
          photoUrl: photoUrl,
        ),
    };
  }

  Future<GoogleAuthResult> _continueWithCredential({
    required String googleIdToken,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      // Legacy compatibility only: exchange the Google credential through
      // Firebase before syncing to the historical protected HTTP backend.
      final credential = fb.GoogleAuthProvider.credential(idToken: googleIdToken);
      final authResult = await _auth.signInWithCredential(credential);
      final firebaseUser = authResult.user;
      if (firebaseUser == null) {
        return const GoogleAuthFailed('Firebase user is null after sign-in.');
      }

      final firebaseIdToken = await firebaseUser.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        return const GoogleAuthFailed('Firebase ID token is missing.');
      }

      final session = AuthSession(
        userId: firebaseUser.uid,
        email: firebaseUser.email,
        phone: firebaseUser.phoneNumber,
        displayName: displayName ?? firebaseUser.displayName,
        photoUrl: photoUrl ?? firebaseUser.photoURL,
      );

      final deviceIdentity = await _deviceIdentityProvider.getIdentity();

      final backendUserState = await _backendUserSyncRepository.syncGoogleUser(
        session: session,
        firebaseIdToken: firebaseIdToken,
        deviceId: deviceIdentity.deviceId,
        deviceFingerprint: deviceIdentity.deviceFingerprint,
        platform: deviceIdentity.platform,
        osVersion: deviceIdentity.osVersion,
      );

      return GoogleAuthComplete(
        session: session,
        backendUserState: backendUserState,
      );
    } catch (e) {
      return GoogleAuthFailed(e.toString());
    }
  }
}

sealed class GoogleAuthResult {
  const GoogleAuthResult();
}

class GoogleAuthComplete extends GoogleAuthResult {
  const GoogleAuthComplete({
    required this.session,
    required this.backendUserState,
  });
  final AuthSession session;
  final BackendUserState backendUserState;
}

class GoogleAuthCancelled extends GoogleAuthResult {
  const GoogleAuthCancelled();
}

class GoogleAuthFailed extends GoogleAuthResult {
  const GoogleAuthFailed(this.message);
  final String message;
}

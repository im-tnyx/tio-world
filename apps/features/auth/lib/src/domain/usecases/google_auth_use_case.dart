import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/auth_session.dart';
import '../models/backend_user_state.dart';
import '../repositories/backend_user_sync_repository.dart';
import '../../data/google_sign_in_provider.dart';
import 'package:tio_shared/shared.dart';

/// Orchestrates the complete Google authentication + backend sync chain.
///
/// PATH B (source-verified from Android AuthViewModel.kt):
/// 1. GoogleSignIn → googleIdToken
/// 2. GoogleAuthProvider.credential(googleIdToken) → GoogleAuthCredential
/// 3. FirebaseAuth.signInWithCredential() → Firebase user
/// 4. firebaseUser.getIdToken(forceRefresh: true) → firebaseIdToken
/// 5. POST /auth/google-sync with firebaseIdToken → backend DB user
/// 6. Firebase session remains established
class GoogleAuthUseCase {
  const GoogleAuthUseCase({
    required GoogleSignInProvider googleSignInProvider,
    required BackendUserSyncRepository backendUserSyncRepository,
    required DeviceIdentityProvider deviceIdentityProvider,
    fb.FirebaseAuth? firebaseAuth,
  })  : _googleSignInProvider = googleSignInProvider,
        _backendUserSyncRepository = backendUserSyncRepository,
        _deviceIdentityProvider = deviceIdentityProvider,
        _firebaseAuth = firebaseAuth;

  final GoogleSignInProvider _googleSignInProvider;
  final BackendUserSyncRepository _backendUserSyncRepository;
  final DeviceIdentityProvider _deviceIdentityProvider;
  final fb.FirebaseAuth? _firebaseAuth;

  fb.FirebaseAuth get _auth => _firebaseAuth ?? fb.FirebaseAuth.instance;

  Future<GoogleAuthResult> call() async {
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
      // Step 2+3: Firebase sign-in with Google credential
      final credential = fb.GoogleAuthProvider.credential(idToken: googleIdToken);
      final authResult = await _auth.signInWithCredential(credential);
      final firebaseUser = authResult.user;
      if (firebaseUser == null) {
        return const GoogleAuthFailed('Firebase user is null after sign-in.');
      }

      // Step 4: Get Firebase ID Token (NOT the Google ID token)
      final firebaseIdToken = await firebaseUser.getIdToken(true);
      if (firebaseIdToken == null || firebaseIdToken.isEmpty) {
        return const GoogleAuthFailed('Firebase ID token is missing.');
      }

      // Build domain session
      final session = AuthSession(
        userId: firebaseUser.uid,
        email: firebaseUser.email,
        phone: firebaseUser.phoneNumber,
        displayName: displayName ?? firebaseUser.displayName,
        photoUrl: photoUrl ?? firebaseUser.photoURL,
      );

      // Step 5: Get device identity
      final deviceIdentity = await _deviceIdentityProvider.getIdentity();

      // Step 6: Backend user sync
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

// --- Result Types ---

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

import '../models/auth_session.dart';
import '../models/backend_user_state.dart';

/// Contract for synchronizing a Firebase-authenticated user
/// to the backend application-user database.
///
/// This is distinct from Firebase authentication:
/// Firebase auth → Firebase UID
/// Backend sync → backend DB user (users.firebase_uid == Firebase UID)
abstract interface class BackendUserSyncRepository {
  /// Synchronizes the authenticated [session] with the backend.
  /// Safe to call repeatedly (idempotent — returns [BackendUserReady] for existing users).
  Future<BackendUserState> syncGoogleUser({
    required AuthSession session,
    required String firebaseIdToken,
    required String deviceId,
    required String deviceFingerprint,
    String? platform,
    String? osVersion,
  });
}

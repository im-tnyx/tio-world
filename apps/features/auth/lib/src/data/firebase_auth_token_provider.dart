import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:tio_shared/shared.dart';

/// Adapter implementing [AuthTokenProvider] backed by [fb.FirebaseAuth].
/// Retrieves the Firebase ID token for the current user, passing [forceRefresh]
/// when requested by the HTTP layer on 401 retry.
class FirebaseAuthTokenProvider implements AuthTokenProvider {
  FirebaseAuthTokenProvider({
    fb.FirebaseAuth? auth,
    Future<String?> Function({bool forceRefresh})? tokenGetter,
  })  : _auth = auth,
        _tokenGetter = tokenGetter;

  final fb.FirebaseAuth? _auth;
  final Future<String?> Function({bool forceRefresh})? _tokenGetter;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (_tokenGetter != null) {
      return _tokenGetter(forceRefresh: forceRefresh);
    }

    final auth = _auth ?? fb.FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      // Return null on token fetch error to trigger safe unauthenticated flow.
      return null;
    }
  }
}

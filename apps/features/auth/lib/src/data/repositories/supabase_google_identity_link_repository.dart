import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/repositories/google_identity_link_repository.dart';

/// Supabase Auth-backed Google identity linker for an already authenticated user.
///
/// This is intentionally different from Google sign-in: linking must keep the
/// current canonical user UUID and add a `google` identity to that same user.
final class SupabaseGoogleIdentityLinkRepository
    implements GoogleIdentityLinkRepository {
  SupabaseGoogleIdentityLinkRepository({
    required SupabaseClient client,
    required GoogleSignIn googleSignIn,
  })  : _client = client,
        _googleSignIn = googleSignIn;

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  @override
  Future<bool> linkGoogleIdentity() async {
    final beforeUser = _client.auth.currentUser;
    if (beforeUser == null || beforeUser.id.isEmpty) {
      throw StateError('Please sign in before connecting Google.');
    }
    final canonicalUserId = beforeUser.id;

    final beforeIdentities = await _client.auth.getUserIdentities();
    if (beforeIdentities.any((identity) => identity.provider == 'google')) {
      return true;
    }

    // Always show an explicit account chooser for a Settings linking action.
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // A stale provider cache must not prevent the linking attempt itself.
    }

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return false;

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken?.trim();
    final accessToken = googleAuth.accessToken?.trim();
    if (idToken == null || idToken.isEmpty) {
      throw StateError('Google ID token is unavailable.');
    }
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Google access token is unavailable.');
    }

    await _client.auth.linkIdentityWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    final afterIdentities = await _client.auth.getUserIdentities();
    final hasGoogleIdentity =
        afterIdentities.any((identity) => identity.provider == 'google');
    if (!hasGoogleIdentity) {
      throw StateError('Supabase Auth did not confirm the Google identity link.');
    }

    // Refresh the session so provider metadata is authoritative for subsequent
    // Account Settings renders and app-level auth state consumers.
    final refreshed = await _client.auth.refreshSession();
    final afterUser = refreshed.user ?? _client.auth.currentUser;
    if (afterUser == null || afterUser.id != canonicalUserId) {
      throw StateError('Google linking changed the canonical authenticated user.');
    }

    return true;
  }
}

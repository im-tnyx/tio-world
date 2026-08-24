import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/models/auth_session_state.dart';
import '../../domain/repositories/auth_session_repository.dart';

/// Supabase-backed implementation of [AuthSessionRepository].
///
/// Maps Supabase GoTrue authentication sessions to domain [AuthSessionState].
class SupabaseAuthSessionRepository implements AuthSessionRepository {
  SupabaseAuthSessionRepository({
    required SupabaseClient client,
  }) : _client = client;

  final SupabaseClient _client;

  @override
  Stream<AuthSessionState> get sessionState async* {
    final initialUser = _client.auth.currentUser;
    if (initialUser != null) {
      yield AuthSessionAuthenticated(_mapUser(initialUser));
    } else {
      yield const AuthSessionUnauthenticated();
    }
    yield* _client.auth.onAuthStateChange.map((data) {
      final session = data.session;
      final user = session?.user ?? _client.auth.currentUser;
      if (user != null) {
        return AuthSessionAuthenticated(_mapUser(user));
      }
      return const AuthSessionUnauthenticated();
    });
  }

  @override
  Future<AuthSessionState> get currentSessionState async {
    final user = _client.auth.currentUser;
    if (user != null) {
      return AuthSessionAuthenticated(_mapUser(user));
    }
    return const AuthSessionUnauthenticated();
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  AuthSession _mapUser(User user) {
    final metadata = user.userMetadata ?? const {};
    final displayName = metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        metadata['display_name'] as String?;
    final photoUrl = metadata['avatar_url'] as String? ??
        metadata['picture'] as String?;

    return AuthSession(
      userId: user.id,
      email: user.email,
      phone: user.phone,
      isEmailVerified: user.emailConfirmedAt != null,
      isPhoneVerified: user.phoneConfirmedAt != null,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}

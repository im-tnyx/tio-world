import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_shared/shared.dart';

/// [AuthTokenProvider] backed by the active Supabase Auth session.
///
/// Production reads use the current session access token. A forced refresh asks
/// Supabase Auth for a new session and returns that session's access token.
/// Missing sessions and SDK/network failures fail closed with `null` so the
/// protected HTTP interceptor rejects the request as unauthenticated.
class SupabaseAuthTokenProvider implements AuthTokenProvider {
  SupabaseAuthTokenProvider({
    required SupabaseClient client,
    String? Function()? currentAccessTokenGetter,
    Future<String?> Function()? refreshAccessTokenGetter,
  })  : _client = client,
        _currentAccessTokenGetter = currentAccessTokenGetter,
        _refreshAccessTokenGetter = refreshAccessTokenGetter;

  final SupabaseClient _client;
  final String? Function()? _currentAccessTokenGetter;
  final Future<String?> Function()? _refreshAccessTokenGetter;

  @override
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final rawToken = forceRefresh
          ? await (_refreshAccessTokenGetter?.call() ?? _refreshAccessToken())
          : (_currentAccessTokenGetter?.call() ??
              _client.auth.currentSession?.accessToken);
      return _normalizeToken(rawToken);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _refreshAccessToken() async {
    final response = await _client.auth.refreshSession();
    return response.session?.accessToken;
  }

  static String? _normalizeToken(String? token) {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    return normalized;
  }
}

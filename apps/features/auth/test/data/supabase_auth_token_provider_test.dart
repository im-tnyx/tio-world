import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SupabaseAuthTokenProvider', () {
    test('returns normalized current session access token', () async {
      final provider = SupabaseAuthTokenProvider(
        client: _FakeSupabaseClient(),
        currentAccessTokenGetter: () => '  current-token  ',
      );

      expect(await provider.getIdToken(), 'current-token');
    });

    test('returns null when the current session has no usable token', () async {
      final provider = SupabaseAuthTokenProvider(
        client: _FakeSupabaseClient(),
        currentAccessTokenGetter: () => '   ',
      );

      expect(await provider.getIdToken(), isNull);
    });

    test('force refresh uses refreshed Supabase access token', () async {
      var refreshCalls = 0;
      final provider = SupabaseAuthTokenProvider(
        client: _FakeSupabaseClient(),
        currentAccessTokenGetter: () => 'stale-token',
        refreshAccessTokenGetter: () async {
          refreshCalls += 1;
          return ' refreshed-token ';
        },
      );

      expect(
        await provider.getIdToken(forceRefresh: true),
        'refreshed-token',
      );
      expect(refreshCalls, 1);
    });

    test('refresh failure fails closed with null', () async {
      final provider = SupabaseAuthTokenProvider(
        client: _FakeSupabaseClient(),
        refreshAccessTokenGetter: () async {
          throw StateError('refresh failed');
        },
      );

      expect(await provider.getIdToken(forceRefresh: true), isNull);
    });

    test('current-session read failure fails closed with null', () async {
      final provider = SupabaseAuthTokenProvider(
        client: _FakeSupabaseClient(),
        currentAccessTokenGetter: () => throw StateError('session unavailable'),
      );

      expect(await provider.getIdToken(), isNull);
    });
  });
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

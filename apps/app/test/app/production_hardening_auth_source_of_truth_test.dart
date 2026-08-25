import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_app/app/network_providers.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('P1 auth source-of-truth alignment', () {
    test('Supabase availability selects both session and token authority', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
          authCapabilityProvider.overrideWithValue(
            const AuthCapabilityAvailable(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(authSessionRepositoryProvider),
        isA<SupabaseAuthSessionRepository>(),
      );
      expect(
        container.read(authTokenProvider),
        isA<SupabaseAuthTokenProvider>(),
      );
    });

    test('Firebase remains aligned fallback only when Supabase is absent', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
          authCapabilityProvider.overrideWithValue(
            const AuthCapabilityAvailable(),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(authSessionRepositoryProvider),
        isA<FirebaseAuthSessionRepository>(),
      );
      expect(
        container.read(authTokenProvider),
        isA<FirebaseAuthTokenProvider>(),
      );
    });

    test('no configured auth provider fails protected token access closed', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
          authCapabilityProvider.overrideWithValue(
            const AuthCapabilityUnavailable('not configured'),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(authSessionRepositoryProvider),
        isA<InMemoryAuthSessionRepository>(),
      );
      expect(
        container.read(authTokenProvider),
        isA<UnavailableAuthTokenProvider>(),
      );
    });
  });
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {}

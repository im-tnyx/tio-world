import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_app/app/composition/auth_providers.dart';
import 'package:tio_app/app/composition/runtime_providers.dart';
import 'package:tio_app/app/composition/workout_providers.dart';
import 'package:tio_feature_auth/auth.dart';
import 'package:tio_feature_workout/workout.dart';

const _testUserId = '11111111-1111-4111-a111-111111111111';

final class _FakeGoTrueClient extends Fake implements GoTrueClient {
  _FakeGoTrueClient({this.currentUserId = _testUserId});

  final String? currentUserId;

  @override
  User? get currentUser => currentUserId != null
      ? User(
          id: currentUserId!,
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2026-11-07T10:00:00Z',
        )
      : null;
}

final class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient({String? currentUserId = _testUserId})
      : _auth = _FakeGoTrueClient(currentUserId: currentUserId);

  final GoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;
}

void main() {
  group('workoutSessionRepositoryProvider', () {
    test('returns null when Supabase client is null (no silent mock fallback)', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(workoutSessionRepositoryProvider), isNull);
    });

    test('returns null when user is unauthenticated', () async {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(_FakeSupabaseClient()),
          authSessionStateProvider.overrideWith(
            (ref) => Stream.value(const AuthSessionUnauthenticated()),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authSessionStateProvider.future);

      expect(container.read(workoutSessionRepositoryProvider), isNull);
    });

    test('returns SupabaseWorkoutSessionRepository when authenticated', () async {
      final client = _FakeSupabaseClient(currentUserId: _testUserId);
      const session = AuthSession(
        userId: _testUserId,
        loginCycleId: 'cycle-1',
      );

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
          authSessionStateProvider.overrideWith(
            (ref) => Stream.value(const AuthSessionAuthenticated(session)),
          ),
        ],
      );
      addTearDown(container.dispose);
      await container.read(authSessionStateProvider.future);

      final repo = container.read(workoutSessionRepositoryProvider);
      expect(repo, isNotNull);
      expect(repo, isA<SupabaseWorkoutSessionRepository>());
    });

    test('invalidates session-local state when auth session transitions or logs out', () async {
      final client = _FakeSupabaseClient(currentUserId: _testUserId);
      const initialSession = AuthSession(
        userId: _testUserId,
        loginCycleId: 'cycle-1',
      );

      final controller = StreamController<AuthSessionState>();
      addTearDown(controller.close);

      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
          authSessionStateProvider.overrideWith((ref) => controller.stream),
        ],
      );
      addTearDown(container.dispose);

      final sub = container.listen(
        workoutSessionRepositoryProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      controller.add(const AuthSessionAuthenticated(initialSession));
      await pumpEventQueue();

      final repo = container.read(workoutSessionRepositoryProvider);
      expect(repo, isNotNull);

      // Simulate sign out
      controller.add(const AuthSessionUnauthenticated());
      await pumpEventQueue();

      // Reading provider after signout yields null
      expect(container.read(workoutSessionRepositoryProvider), isNull);
    });
  });
}

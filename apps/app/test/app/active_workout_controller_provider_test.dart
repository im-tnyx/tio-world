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
  group('activeWorkoutControllerProvider', () {
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

      expect(container.read(activeWorkoutControllerProvider), isNull);
    });

    test('returns null when Supabase client is null', () {
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(null),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(activeWorkoutControllerProvider), isNull);
    });

    test('returns ActiveWorkoutController when authenticated', () async {
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

      final controller = container.read(activeWorkoutControllerProvider);
      expect(controller, isNotNull);
      expect(controller, isA<ActiveWorkoutController>());
      expect(controller!.state.status, ActiveWorkoutStatus.initial);
    });

    test('retains repository and controller across same-login profile and verification updates', () async {
      final client = _FakeSupabaseClient(currentUserId: _testUserId);
      final authEvents = StreamController<AuthSessionState>();
      addTearDown(authEvents.close);
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
          authSessionStateProvider.overrideWith((ref) => authEvents.stream),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        activeWorkoutControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      const initial = AuthSession(userId: _testUserId, loginCycleId: 'cycle-1');
      authEvents.add(const AuthSessionAuthenticated(initial));
      await pumpEventQueue();
      final initialRepository = container.read(workoutSessionRepositoryProvider);
      final initialController = container.read(activeWorkoutControllerProvider);
      expect(initialRepository, isNotNull);
      expect(initialController, isNotNull);
      initialController!.startRestTimer(durationSeconds: 60);

      for (final updated in const [
        AuthSession(
          userId: _testUserId,
          loginCycleId: 'cycle-1',
          displayName: 'Updated name',
        ),
        AuthSession(
          userId: _testUserId,
          loginCycleId: 'cycle-1',
          photoUrl: 'https://example.invalid/avatar.png',
        ),
        AuthSession(
          userId: _testUserId,
          loginCycleId: 'cycle-1',
          isEmailVerified: true,
        ),
      ]) {
        authEvents.add(AuthSessionAuthenticated(updated));
        await pumpEventQueue();
        expect(container.read(workoutSessionRepositoryProvider), same(initialRepository));
        expect(container.read(activeWorkoutControllerProvider), same(initialController));
        expect(initialController.state.activeRestTimer, isNotNull);
      }
    });

    test('rebuilds controller for a new login cycle and never retains old capability', () async {
      final client = _FakeSupabaseClient(currentUserId: _testUserId);
      final authEvents = StreamController<AuthSessionState>();
      addTearDown(authEvents.close);
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
          authSessionStateProvider.overrideWith((ref) => authEvents.stream),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        activeWorkoutControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      authEvents.add(const AuthSessionAuthenticated(
        AuthSession(userId: _testUserId, loginCycleId: 'cycle-1'),
      ));
      await pumpEventQueue();
      final first = container.read(activeWorkoutControllerProvider);
      expect(first, isNotNull);

      authEvents.add(const AuthSessionAuthenticated(
        AuthSession(userId: _testUserId, loginCycleId: 'cycle-2'),
      ));
      await pumpEventQueue();
      final second = container.read(activeWorkoutControllerProvider);
      expect(second, isNotNull);
      expect(second, isNot(same(first)));
    });

    test('fails closed after account switch or repeated unauthenticated auth events', () async {
      final client = _FakeSupabaseClient(currentUserId: _testUserId);
      final authEvents = StreamController<AuthSessionState>();
      addTearDown(authEvents.close);
      final container = ProviderContainer(
        overrides: [
          supabaseClientProvider.overrideWithValue(client),
          authSessionStateProvider.overrideWith((ref) => authEvents.stream),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        activeWorkoutControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      authEvents.add(const AuthSessionAuthenticated(
        AuthSession(userId: _testUserId, loginCycleId: 'cycle-1'),
      ));
      await pumpEventQueue();
      final previousUserController = container.read(activeWorkoutControllerProvider);
      expect(previousUserController, isNotNull);

      authEvents.add(const AuthSessionAuthenticated(AuthSession(
        userId: '22222222-2222-4222-a222-222222222222',
        loginCycleId: 'cycle-2',
      )));
      await pumpEventQueue();
      expect(container.read(activeWorkoutControllerProvider), isNull);

      authEvents.add(const AuthSessionUnauthenticated());
      authEvents.add(const AuthSessionUnauthenticated());
      await pumpEventQueue();
      expect(container.read(activeWorkoutControllerProvider), isNull);
      expect(
        previousUserController!.state.status,
        ActiveWorkoutStatus.authInvalidated,
      );
    });

    test('invalidates controller when auth state transitions to signout', () async {
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
        activeWorkoutControllerProvider,
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      controller.add(const AuthSessionAuthenticated(initialSession));
      await pumpEventQueue();

      final activeCtrl = container.read(activeWorkoutControllerProvider);
      expect(activeCtrl, isNotNull);

      // Simulate sign out
      controller.add(const AuthSessionUnauthenticated());
      await pumpEventQueue();

      // Controller becomes null after sign out
      expect(container.read(activeWorkoutControllerProvider), isNull);
    });
  });
}

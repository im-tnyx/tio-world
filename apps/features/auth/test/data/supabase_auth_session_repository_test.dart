import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SupabaseAuthSessionRepository', () {
    test('instantiates with client', () {
      expect(
        () => SupabaseAuthSessionRepository(
          client: FakeSupabaseClient(),
        ),
        returnsNormally,
      );
    });

    test('currentSessionState returns unauthenticated when no user is signed in', () async {
      final repository = SupabaseAuthSessionRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final state = await repository.currentSessionState;
      expect(state, isA<AuthSessionUnauthenticated>());
    });

    test('currentSessionState returns authenticated when user is signed in', () async {
      final fakeUser = User(
        id: 'usr-1234',
        appMetadata: const {
          'provider': 'phone',
          'providers': ['phone', 'email'],
        },
        userMetadata: const {
          'full_name': 'Sarah Connor',
          'avatar_url': 'https://example.com/avatar.png',
        },
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'sarah@example.com',
        phone: '+1234567890',
      );

      final repository = SupabaseAuthSessionRepository(
        client: FakeSupabaseClient(currentUser: fakeUser),
      );

      final state = await repository.currentSessionState;
      expect(state, isA<AuthSessionAuthenticated>());
      final authSession = (state as AuthSessionAuthenticated).session;
      expect(authSession.userId, 'usr-1234');
      expect(authSession.displayName, 'Sarah Connor');
      expect(authSession.email, 'sarah@example.com');
      expect(authSession.phone, '+1234567890');
      expect(authSession.photoUrl, 'https://example.com/avatar.png');
      expect(authSession.identityProviders, containsAll(['phone', 'email']));
      expect(authSession.identityProviders, isNot(contains('google')));
    });

    test('maps Google only when Supabase reports a Google identity', () async {
      final fakeUser = User(
        id: 'usr-google',
        appMetadata: const {
          'provider': 'google',
          'providers': ['google'],
        },
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'google@example.com',
        emailConfirmedAt: DateTime.now().toIso8601String(),
      );

      final repository = SupabaseAuthSessionRepository(
        client: FakeSupabaseClient(currentUser: fakeUser),
      );

      final state = await repository.currentSessionState;
      final authSession = (state as AuthSessionAuthenticated).session;

      expect(authSession.identityProviders, {'google'});
    });

    test('sessionState stream emits initial unauthenticated state immediately', () async {
      final repository = SupabaseAuthSessionRepository(
        client: FakeSupabaseClient(currentUser: null),
      );

      final state = await repository.sessionState.first;
      expect(state, isA<AuthSessionUnauthenticated>());
    });

    test('sessionState stream emits initial authenticated state immediately', () async {
      final fakeUser = User(
        id: 'usr-999',
        appMetadata: const {},
        userMetadata: const {'full_name': 'John Doe'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );

      final repository = SupabaseAuthSessionRepository(
        client: FakeSupabaseClient(currentUser: fakeUser),
      );

      final state = await repository.sessionState.first;
      expect(state, isA<AuthSessionAuthenticated>());
      expect((state as AuthSessionAuthenticated).session.userId, 'usr-999');
    });

    test('signOut calls client.auth.signOut', () async {
      final fakeGoTrue = FakeGoTrueClient();
      final fakeClient = FakeSupabaseClient(goTrueClient: fakeGoTrue);
      final repository = SupabaseAuthSessionRepository(client: fakeClient);

      await repository.signOut();
      expect(fakeGoTrue.signOutCalled, isTrue);
    });
  });
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient({this.currentUser, FakeGoTrueClient? goTrueClient})
      : _goTrueClient = goTrueClient ?? FakeGoTrueClient(currentUser: currentUser);

  final User? currentUser;
  final FakeGoTrueClient _goTrueClient;

  @override
  GoTrueClient get auth => _goTrueClient;
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  FakeGoTrueClient({this.currentUser});

  @override
  final User? currentUser;
  bool signOutCalled = false;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<void> signOut({SignOutScope scope = SignOutScope.global}) async {
    signOutCalled = true;
  }
}

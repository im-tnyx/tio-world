import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SupabaseGoogleIdentityLinkRepository', () {
    test('requires an authenticated user before linking', () async {
      final auth = _FakeGoTrueClient(currentUser: null);
      final repository = SupabaseGoogleIdentityLinkRepository(
        client: _FakeSupabaseClient(auth),
        googleSignIn: _FakeGoogleSignIn(),
      );

      await expectLater(
        repository.linkGoogleIdentity(),
        throwsA(isA<StateError>()),
      );
      expect(auth.linkCalls, 0);
    });

    test('already linked Google identity returns true without chooser', () async {
      final currentUser = _user('user-1');
      final auth = _FakeGoTrueClient(
        currentUser: currentUser,
        identities: [_identity(provider: 'phone'), _identity(provider: 'google')],
      );
      final google = _FakeGoogleSignIn();
      final repository = SupabaseGoogleIdentityLinkRepository(
        client: _FakeSupabaseClient(auth),
        googleSignIn: google,
      );

      expect(await repository.linkGoogleIdentity(), isTrue);
      expect(google.signInCalls, 0);
      expect(auth.linkCalls, 0);
    });

    test('cancelled Google chooser returns false and does not link', () async {
      final currentUser = _user('user-1');
      final auth = _FakeGoTrueClient(
        currentUser: currentUser,
        identities: [_identity(provider: 'phone')],
      );
      final google = _FakeGoogleSignIn(accountToReturn: null);
      final repository = SupabaseGoogleIdentityLinkRepository(
        client: _FakeSupabaseClient(auth),
        googleSignIn: google,
      );

      expect(await repository.linkGoogleIdentity(), isFalse);
      expect(google.signInCalls, 1);
      expect(auth.linkCalls, 0);
    });

    test('links Google tokens, confirms identity, refreshes, and keeps UUID',
        () async {
      final currentUser = _user('user-1');
      final auth = _FakeGoTrueClient(
        currentUser: currentUser,
        identities: [_identity(provider: 'phone'), _identity(provider: 'email')],
        addGoogleIdentityAfterLink: true,
        refreshedUser: currentUser,
      );
      final google = _FakeGoogleSignIn(
        accountToReturn: _FakeGoogleAccount(),
      );
      final repository = SupabaseGoogleIdentityLinkRepository(
        client: _FakeSupabaseClient(auth),
        googleSignIn: google,
      );

      expect(await repository.linkGoogleIdentity(), isTrue);
      expect(auth.linkCalls, 1);
      expect(auth.lastProvider, OAuthProvider.google);
      expect(auth.lastIdToken, 'google-id-token');
      expect(auth.lastAccessToken, 'google-access-token');
      expect(auth.refreshCalls, 1);
      expect(auth.identities.any((identity) => identity.provider == 'google'), isTrue);
    });

    test('does not claim success when Supabase lacks Google identity evidence',
        () async {
      final currentUser = _user('user-1');
      final auth = _FakeGoTrueClient(
        currentUser: currentUser,
        identities: [_identity(provider: 'phone')],
        addGoogleIdentityAfterLink: false,
      );
      final repository = SupabaseGoogleIdentityLinkRepository(
        client: _FakeSupabaseClient(auth),
        googleSignIn: _FakeGoogleSignIn(
          accountToReturn: _FakeGoogleAccount(),
        ),
      );

      await expectLater(
        repository.linkGoogleIdentity(),
        throwsA(isA<StateError>()),
      );
      expect(auth.refreshCalls, 0);
    });

    test('fails closed if refreshed session changes canonical UUID', () async {
      final currentUser = _user('user-1');
      final auth = _FakeGoTrueClient(
        currentUser: currentUser,
        identities: [_identity(provider: 'phone')],
        addGoogleIdentityAfterLink: true,
        refreshedUser: _user('different-user'),
      );
      final repository = SupabaseGoogleIdentityLinkRepository(
        client: _FakeSupabaseClient(auth),
        googleSignIn: _FakeGoogleSignIn(
          accountToReturn: _FakeGoogleAccount(),
        ),
      );

      await expectLater(
        repository.linkGoogleIdentity(),
        throwsA(isA<StateError>()),
      );
      expect(auth.refreshCalls, 1);
    });
  });
}

User _user(String id) {
  return User(
    id: id,
    appMetadata: const {
      'provider': 'phone',
      'providers': ['phone', 'email'],
    },
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-08-27T00:00:00.000Z',
    phone: '+919123456789',
    phoneConfirmedAt: '2026-08-27T00:00:00.000Z',
  );
}

UserIdentity _identity({required String provider}) {
  return UserIdentity(
    id: 'identity-$provider',
    userId: 'user-1',
    identityData: const {},
    identityId: 'provider-$provider',
    provider: provider,
    createdAt: '2026-08-27T00:00:00.000Z',
    lastSignInAt: '2026-08-27T00:00:00.000Z',
  );
}

class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this._auth);

  final GoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;
}

class _FakeGoTrueClient extends Fake implements GoTrueClient {
  _FakeGoTrueClient({
    required this.currentUser,
    List<UserIdentity>? identities,
    this.addGoogleIdentityAfterLink = false,
    this.refreshedUser,
  }) : identities = [...?identities];

  @override
  final User? currentUser;

  final List<UserIdentity> identities;
  final bool addGoogleIdentityAfterLink;
  final User? refreshedUser;

  int linkCalls = 0;
  int refreshCalls = 0;
  OAuthProvider? lastProvider;
  String? lastIdToken;
  String? lastAccessToken;

  @override
  Future<List<UserIdentity>> getUserIdentities() async => List.of(identities);

  @override
  Future<AuthResponse> linkIdentityWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
    String? captchaToken,
  }) async {
    linkCalls++;
    lastProvider = provider;
    lastIdToken = idToken;
    lastAccessToken = accessToken;
    if (addGoogleIdentityAfterLink &&
        !identities.any((identity) => identity.provider == 'google')) {
      identities.add(_identity(provider: 'google'));
    }
    return AuthResponse(session: null, user: currentUser);
  }

  @override
  Future<AuthResponse> refreshSession([String? refreshToken]) async {
    refreshCalls++;
    return AuthResponse(
      session: null,
      user: refreshedUser ?? currentUser,
    );
  }
}

class _FakeGoogleSignIn extends GoogleSignIn {
  _FakeGoogleSignIn({this.accountToReturn});

  final GoogleSignInAccount? accountToReturn;
  int signInCalls = 0;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCalls++;
    return accountToReturn;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async => null;
}

class _FakeGoogleAccount implements GoogleSignInAccount {
  @override
  String get displayName => 'Test Member';

  @override
  String get email => 'member@example.com';

  @override
  String get id => 'google-user';

  @override
  String get photoUrl => '';

  @override
  String? get serverAuthCode => null;

  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _FakeGoogleAuthentication();

  @override
  Future<Map<String, String>> get authHeaders async => const {};

  @override
  Future<void> clearAuthCache() async {}
}

class _FakeGoogleAuthentication implements GoogleSignInAuthentication {
  @override
  String? get accessToken => 'google-access-token';

  @override
  String? get idToken => 'google-id-token';

  @override
  String? get serverAuthCode => null;
}

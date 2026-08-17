import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('SupabaseAuthSignInRepository', () {
    test('instantiates with SupabaseClient', () {
      final fakeClient = FakeSupabaseClient();
      final repo = SupabaseAuthSignInRepository(client: fakeClient);
      expect(repo, isNotNull);
    });

    test('signInWithGoogle clears cached account before interactive selection', () async {
      final fakeClient = FakeSupabaseClient();
      final fakeGoogleSignIn = FakeGoogleSignIn(accountToReturn: null);
      final repo = SupabaseAuthSignInRepository(
        client: fakeClient,
        googleSignIn: fakeGoogleSignIn,
      );

      final result = await repo.signInWithGoogle();

      expect(fakeGoogleSignIn.signOutCalls, 1);
      expect(fakeGoogleSignIn.signInCalls, 1);
      expect(result, isA<SignInCancelled>());
    });

    test('Google account selection timeout returns controlled failure', () async {
      final pendingSelection = Completer<GoogleSignInAccount?>();
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(),
        googleSignIn: FakeGoogleSignIn(signInFuture: pendingSelection.future),
        googleAccountSelectionTimeout: const Duration(milliseconds: 10),
      );

      final result = await repo.signInWithGoogle();

      expect(result, isA<SignInFailure>());
      expect(
        (result as SignInFailure).code,
        'google_account_selection_timeout',
      );
    });

    test('Google credential timeout returns controlled failure', () async {
      final pendingCredentials = Completer<GoogleSignInAuthentication>();
      final account = FakeGoogleSignInAccount(
        authenticationFuture: pendingCredentials.future,
      );
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(),
        googleSignIn: FakeGoogleSignIn(accountToReturn: account),
        googleCredentialTimeout: const Duration(milliseconds: 10),
      );

      final result = await repo.signInWithGoogle();

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'google_credential_timeout');
    });

    test('Supabase Google exchange timeout returns controlled failure', () async {
      final pendingExchange = Completer<AuthResponse>();
      final fakeGoTrue = FakeGoTrueClient(idTokenFuture: pendingExchange.future);
      final account = FakeGoogleSignInAccount(
        authenticationFuture: Future.value(
          FakeGoogleSignInAuthentication(
            idToken: 'google-id-token',
            accessToken: 'google-access-token',
          ),
        ),
      );
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(accountToReturn: account),
        googleSupabaseExchangeTimeout: const Duration(milliseconds: 10),
      );

      final result = await repo.signInWithGoogle();

      expect(result, isA<SignInFailure>());
      expect(
        (result as SignInFailure).code,
        'google_supabase_exchange_timeout',
      );
    });

    test('Google sign-in succeeds when every critical stage completes', () async {
      final fakeUser = User(
        id: 'usr-google-1',
        appMetadata: const {},
        userMetadata: const {'full_name': 'Google User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'google@test.com',
      );
      final fakeGoTrue = FakeGoTrueClient(
        currentUser: fakeUser,
        authResponseToReturn: AuthResponse(
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: fakeUser,
          ),
          user: fakeUser,
        ),
      );
      final account = FakeGoogleSignInAccount(
        authenticationFuture: Future.value(
          FakeGoogleSignInAuthentication(
            idToken: 'google-id-token',
            accessToken: 'google-access-token',
          ),
        ),
      );
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(accountToReturn: account),
      );

      final result = await repo.signInWithGoogle();

      expect(result, isA<SignInSuccess>());
      expect((result as SignInSuccess).session.userId, 'usr-google-1');
      expect(result.session.email, 'google@test.com');
    });

    test('signInWithEmailPassword returns SignInSuccess on valid credentials', () async {
      final fakeUser = User(
        id: 'usr-email-1',
        appMetadata: const {},
        userMetadata: {'full_name': 'Email User'},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'user@test.com',
      );
      final fakeGoTrue = FakeGoTrueClient(
        currentUser: fakeUser,
        authResponseToReturn: AuthResponse(
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: fakeUser,
          ),
          user: fakeUser,
        ),
      );
      final fakeClient = FakeSupabaseClient(goTrueClient: fakeGoTrue);
      final repo = SupabaseAuthSignInRepository(client: fakeClient);

      final result = await repo.signInWithEmailPassword(
        email: 'user@test.com',
        password: 'password123',
      );

      expect(result, isA<SignInSuccess>());
      expect((result as SignInSuccess).session.userId, equals('usr-email-1'));
      expect(result.session.email, equals('user@test.com'));
      expect(result.session.displayName, equals('Email User'));
    });

    test('successful sign-in does not wait for secondary device sync', () async {
      final fakeUser = User(
        id: 'usr-email-2',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
        email: 'user2@test.com',
      );
      final fakeGoTrue = FakeGoTrueClient(
        currentUser: fakeUser,
        authResponseToReturn: AuthResponse(
          session: Session(
            accessToken: 'token',
            tokenType: 'bearer',
            user: fakeUser,
          ),
          user: fakeUser,
        ),
      );
      final deviceRepository = PendingUserDeviceRepository();
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        userDeviceRepository: deviceRepository,
      );

      final result = await repo
          .signInWithEmailPassword(
            email: 'user2@test.com',
            password: 'password123',
          )
          .timeout(const Duration(milliseconds: 200));

      expect(result, isA<SignInSuccess>());
      expect(deviceRepository.syncCalls, 1);

      deviceRepository.complete();
    });

    test('signInWithEmailPassword returns SignInFailure on AuthException', () async {
      final fakeGoTrue = FakeGoTrueClient(
        exceptionToThrow: const AuthException('Invalid login credentials', statusCode: '400'),
      );
      final fakeClient = FakeSupabaseClient(goTrueClient: fakeGoTrue);
      final repo = SupabaseAuthSignInRepository(client: fakeClient);

      final result = await repo.signInWithEmailPassword(
        email: 'bad@test.com',
        password: 'wrong',
      );

      expect(result, isA<SignInFailure>());
      final failure = result as SignInFailure;
      expect(failure.message, equals('Invalid login credentials'));
      expect(failure.code, equals('400'));
    });
  });
}

class PendingUserDeviceRepository implements UserDeviceRepository {
  final Completer<void> _completer = Completer<void>();
  int syncCalls = 0;

  @override
  Future<void> syncCurrentDevice() {
    syncCalls++;
    return _completer.future;
  }

  void complete() {
    if (!_completer.isCompleted) {
      _completer.complete();
    }
  }
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
  FakeGoTrueClient({
    this.currentUser,
    this.authResponseToReturn,
    this.exceptionToThrow,
    this.idTokenFuture,
  });

  @override
  final User? currentUser;
  final AuthResponse? authResponseToReturn;
  final Object? exceptionToThrow;
  final Future<AuthResponse>? idTokenFuture;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    return authResponseToReturn ??
        AuthResponse(
          session: null,
          user: currentUser,
        );
  }

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
    String? captchaToken,
  }) async {
    if (exceptionToThrow != null) {
      throw exceptionToThrow!;
    }
    final pending = idTokenFuture;
    if (pending != null) return pending;
    return authResponseToReturn ??
        AuthResponse(
          session: null,
          user: currentUser,
        );
  }
}

class FakeGoogleSignIn extends Fake implements GoogleSignIn {
  FakeGoogleSignIn({this.accountToReturn, this.signInFuture});

  final GoogleSignInAccount? accountToReturn;
  final Future<GoogleSignInAccount?>? signInFuture;
  int signOutCalls = 0;
  int signInCalls = 0;

  @override
  Future<GoogleSignInAccount?> signOut() async {
    signOutCalls++;
    return null;
  }

  @override
  Future<GoogleSignInAccount?> signIn() async {
    signInCalls++;
    final pending = signInFuture;
    if (pending != null) return pending;
    return accountToReturn;
  }
}

class FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  FakeGoogleSignInAccount({required this.authenticationFuture});

  final Future<GoogleSignInAuthentication> authenticationFuture;

  @override
  Future<GoogleSignInAuthentication> get authentication => authenticationFuture;
}

class FakeGoogleSignInAuthentication extends Fake
    implements GoogleSignInAuthentication {
  FakeGoogleSignInAuthentication({
    required this.idToken,
    this.accessToken,
  });

  @override
  final String? idToken;

  @override
  final String? accessToken;

  @override
  String? get serverAuthCode => null;
}

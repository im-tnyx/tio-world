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

    test('signInWithGoogle clears cached account before interactive selection',
        () async {
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

    test('existing-account Login rejects unknown Google identity before exchange',
        () async {
      final fakeGoTrue = FakeGoTrueClient();
      final account = _googleAccountWithTokens();
      var admissionCalls = 0;
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(accountToReturn: account),
        googleLoginAdmissionChecker: (idToken) async {
          admissionCalls++;
          expect(idToken, 'google-id-token');
          return GoogleLoginAdmissionDecision.noAccount;
        },
      );

      final result = await repo.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.existingAccountOnly,
      );

      expect(admissionCalls, 1);
      expect(fakeGoTrue.idTokenCalls, 0);
      expect(result, isA<SignInFailure>());
      final failure = result as SignInFailure;
      expect(failure.code, 'google_account_not_found');
      expect(
        failure.message,
        'No Tio account found for this Google account.\n'
        'Create a Tio account first to continue.',
      );
    });

    test('existing-account Login proceeds after admission succeeds', () async {
      final fakeUser = _googleUser();
      final fakeGoTrue = FakeGoTrueClient(
        currentUser: fakeUser,
        authResponseToReturn: _authResponse(fakeUser),
      );
      var admissionCalls = 0;
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(
          accountToReturn: _googleAccountWithTokens(),
        ),
        googleLoginAdmissionChecker: (_) async {
          admissionCalls++;
          return GoogleLoginAdmissionDecision.existingAccount;
        },
      );

      final result = await repo.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.existingAccountOnly,
      );

      expect(admissionCalls, 1);
      expect(fakeGoTrue.idTokenCalls, 1);
      expect(result, isA<SignInSuccess>());
    });

    test('signup-capable Google flow classifies account without gating exchange',
        () async {
      final fakeUser = _googleUser();
      final fakeGoTrue = FakeGoTrueClient(
        currentUser: fakeUser,
        authResponseToReturn: _authResponse(fakeUser),
      );
      var classificationCalls = 0;
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(
          accountToReturn: _googleAccountWithTokens(),
        ),
        googleLoginAdmissionChecker: (_) async {
          classificationCalls++;
          return GoogleLoginAdmissionDecision.noAccount;
        },
      );

      final result = await repo.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.signupOrExisting,
      );

      expect(classificationCalls, 1);
      expect(fakeGoTrue.idTokenCalls, 1);
      expect(result, isA<SignInSuccess>());
    });

    test('admission infrastructure failure is retryable and not no-account',
        () async {
      final fakeGoTrue = FakeGoTrueClient();
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(
          accountToReturn: _googleAccountWithTokens(),
        ),
        googleLoginAdmissionChecker: (_) async {
          throw StateError('network unavailable');
        },
      );

      final result = await repo.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.existingAccountOnly,
      );

      expect(fakeGoTrue.idTokenCalls, 0);
      expect(result, isA<SignInFailure>());
      final failure = result as SignInFailure;
      expect(failure.code, 'google_login_admission_failed');
      expect(failure.code, isNot('google_account_not_found'));
    });

    test('existing-account Login does not fall back to signup-capable OAuth',
        () async {
      final fakeGoTrue = FakeGoTrueClient();
      final account = FakeGoogleSignInAccount(
        authenticationFuture: Future.value(
          FakeGoogleSignInAuthentication(idToken: null),
        ),
      );
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(accountToReturn: account),
      );

      final result = await repo.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.existingAccountOnly,
      );

      expect(fakeGoTrue.idTokenCalls, 0);
      expect(result, isA<SignInFailure>());
      expect(
        (result as SignInFailure).code,
        'google_login_admission_token_unavailable',
      );
    });

    test('Supabase Google exchange timeout returns controlled failure', () async {
      final pendingExchange = Completer<AuthResponse>();
      final fakeGoTrue = FakeGoTrueClient(idTokenFuture: pendingExchange.future);
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(
          accountToReturn: _googleAccountWithTokens(),
        ),
        googleLoginAdmissionChecker: (_) async =>
            GoogleLoginAdmissionDecision.existingAccount,
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
      final fakeUser = _googleUser();
      final fakeGoTrue = FakeGoTrueClient(
        currentUser: fakeUser,
        authResponseToReturn: _authResponse(fakeUser),
      );
      final repo = SupabaseAuthSignInRepository(
        client: FakeSupabaseClient(goTrueClient: fakeGoTrue),
        googleSignIn: FakeGoogleSignIn(
          accountToReturn: _googleAccountWithTokens(),
        ),
        googleLoginAdmissionChecker: (_) async =>
            GoogleLoginAdmissionDecision.existingAccount,
      );

      final result = await repo.signInWithGoogle();

      expect(result, isA<SignInSuccess>());
      expect((result as SignInSuccess).session.userId, 'usr-google-1');
      expect(result.session.email, 'google@test.com');
    });

    test('signInWithEmailPassword returns SignInSuccess on valid credentials',
        () async {
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

    test('signInWithEmailPassword returns SignInFailure on AuthException',
        () async {
      final fakeGoTrue = FakeGoTrueClient(
        exceptionToThrow:
            const AuthException('Invalid login credentials', statusCode: '400'),
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

User _googleUser() => User(
      id: 'usr-google-1',
      appMetadata: const {},
      userMetadata: const {'full_name': 'Google User'},
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: 'google@test.com',
    );

AuthResponse _authResponse(User user) => AuthResponse(
      session: Session(
        accessToken: 'token',
        tokenType: 'bearer',
        user: user,
      ),
      user: user,
    );

FakeGoogleSignInAccount _googleAccountWithTokens() => FakeGoogleSignInAccount(
      authenticationFuture: Future.value(
        FakeGoogleSignInAuthentication(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      ),
    );

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
      : _goTrueClient =
            goTrueClient ?? FakeGoTrueClient(currentUser: currentUser);

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
  int idTokenCalls = 0;

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
    idTokenCalls++;
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

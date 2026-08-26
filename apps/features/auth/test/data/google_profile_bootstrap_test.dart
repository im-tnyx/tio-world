import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tio_feature_auth/auth.dart';

void main() {
  group('Google profile bootstrap', () {
    test('fresh signup imports the Google photo once', () async {
      final user = _googleUser(photoUrl: 'https://example.com/google.jpg');
      final sync = ProfileSyncRecorder();
      var admissionCalls = 0;
      final repository = _repository(
        user: user,
        profileSync: sync.call,
        admissionChecker: (_) async {
          admissionCalls++;
          return GoogleLoginAdmissionDecision.noAccount;
        },
      );

      final result = await repository.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.signupOrExisting,
      );
      await sync.completed.future.timeout(const Duration(seconds: 1));

      expect(result, isA<SignInSuccess>());
      expect(admissionCalls, 1);
      expect(sync.calls, 1);
      expect(sync.importProviderPhoto, isTrue);
      expect(sync.photoUrl, 'https://example.com/google.jpg');
    });

    test('returning linked identity never overwrites a custom avatar', () async {
      final sync = ProfileSyncRecorder();
      final repository = _repository(
        user: _googleUser(photoUrl: 'https://example.com/google-new.jpg'),
        profileSync: sync.call,
        admissionChecker: (_) async =>
            GoogleLoginAdmissionDecision.linkedAccount,
      );

      final result = await repository.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.signupOrExisting,
      );
      await sync.completed.future.timeout(const Duration(seconds: 1));

      expect(result, isA<SignInSuccess>());
      expect(sync.calls, 1);
      expect(sync.importProviderPhoto, isFalse);
    });

    test('existing-account Login never imports the provider photo', () async {
      final sync = ProfileSyncRecorder();
      final repository = _repository(
        user: _googleUser(photoUrl: 'https://example.com/google.jpg'),
        profileSync: sync.call,
        admissionChecker: (_) async =>
            GoogleLoginAdmissionDecision.linkedAccount,
      );

      final result = await repository.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.existingAccountOnly,
      );
      await sync.completed.future.timeout(const Duration(seconds: 1));

      expect(result, isA<SignInSuccess>());
      expect(sync.calls, 1);
      expect(sync.importProviderPhoto, isFalse);
    });

    test('admission failure blocks signup before profile enrichment', () async {
      final sync = ProfileSyncRecorder();
      final repository = _repository(
        user: _googleUser(photoUrl: 'https://example.com/google.jpg'),
        profileSync: sync.call,
        admissionChecker: (_) async => throw StateError('resolver unavailable'),
      );

      final result = await repository.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.signupOrExisting,
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'google_login_admission_failed');
      expect(sync.calls, 0);
    });

    test('link-required identity never reaches profile enrichment', () async {
      final sync = ProfileSyncRecorder();
      final repository = _repository(
        user: _googleUser(photoUrl: 'https://example.com/google.jpg'),
        profileSync: sync.call,
        admissionChecker: (_) async =>
            GoogleLoginAdmissionDecision.linkRequired,
      );

      final result = await repository.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.signupOrExisting,
      );

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).code, 'google_account_link_required');
      expect(sync.calls, 0);
    });

    test('missing Google photo remains a valid fresh signup', () async {
      final sync = ProfileSyncRecorder();
      final repository = _repository(
        user: _googleUser(),
        profileSync: sync.call,
        admissionChecker: (_) async => GoogleLoginAdmissionDecision.noAccount,
      );

      final result = await repository.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.signupOrExisting,
      );
      await sync.completed.future.timeout(const Duration(seconds: 1));

      expect(result, isA<SignInSuccess>());
      expect(sync.importProviderPhoto, isTrue);
      expect(sync.photoUrl, isNull);
    });

    test('profile enrichment failure is non-critical to authentication',
        () async {
      final attempted = Completer<void>();
      final repository = _repository(
        user: _googleUser(photoUrl: 'https://example.com/google.jpg'),
        admissionChecker: (_) async => GoogleLoginAdmissionDecision.noAccount,
        profileSync: ({
          required User user,
          required AuthSession session,
          required bool importProviderPhoto,
        }) async {
          if (!attempted.isCompleted) attempted.complete();
          throw StateError('profile write unavailable');
        },
      );

      final result = await repository.signInWithGoogleForIntent(
        intent: GoogleSignInIntent.signupOrExisting,
      );
      await attempted.future.timeout(const Duration(seconds: 1));

      expect(result, isA<SignInSuccess>());
    });
  });
}

SupabaseAuthSignInRepository _repository({
  required User user,
  required GoogleLoginAdmissionChecker admissionChecker,
  required GoogleProfileSyncCallback profileSync,
}) {
  final goTrue = FakeGoTrueClient(
    currentUser: user,
    response: _authResponse(user),
  );
  return SupabaseAuthSignInRepository(
    client: FakeSupabaseClient(goTrue),
    googleSignIn: FakeGoogleSignIn(_googleAccountWithTokens()),
    googleLoginAdmissionChecker: admissionChecker,
    googleProfileSyncCallback: profileSync,
  );
}

User _googleUser({String? photoUrl}) => User(
      id: 'usr-google-photo',
      appMetadata: const {},
      userMetadata: {
        'full_name': 'Google User',
        if (photoUrl != null) 'avatar_url': photoUrl,
      },
      aud: 'authenticated',
      createdAt: DateTime.now().toIso8601String(),
      email: 'google-photo@test.com',
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
      Future.value(
        FakeGoogleSignInAuthentication(
          idToken: 'google-id-token',
          accessToken: 'google-access-token',
        ),
      ),
    );

class ProfileSyncRecorder {
  final Completer<void> completed = Completer<void>();
  int calls = 0;
  bool? importProviderPhoto;
  String? photoUrl;

  Future<void> call({
    required User user,
    required AuthSession session,
    required bool importProviderPhoto,
  }) async {
    calls++;
    this.importProviderPhoto = importProviderPhoto;
    photoUrl = session.photoUrl;
    if (!completed.isCompleted) completed.complete();
  }
}

class FakeSupabaseClient extends Fake implements SupabaseClient {
  FakeSupabaseClient(this._auth);

  final GoTrueClient _auth;

  @override
  GoTrueClient get auth => _auth;
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  FakeGoTrueClient({required this.currentUser, required this.response});

  @override
  final User currentUser;
  final AuthResponse response;

  @override
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
    String? captchaToken,
  }) async {
    return response;
  }
}

class FakeGoogleSignIn extends Fake implements GoogleSignIn {
  FakeGoogleSignIn(this.account);

  final GoogleSignInAccount account;

  @override
  Future<GoogleSignInAccount?> signOut() async => null;

  @override
  Future<GoogleSignInAccount?> signIn() async => account;
}

class FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  FakeGoogleSignInAccount(this.authenticationFuture);

  final Future<GoogleSignInAuthentication> authenticationFuture;

  @override
  Future<GoogleSignInAuthentication> get authentication => authenticationFuture;
}

class FakeGoogleSignInAuthentication extends Fake
    implements GoogleSignInAuthentication {
  FakeGoogleSignInAuthentication({required this.idToken, this.accessToken});

  @override
  final String? idToken;

  @override
  final String? accessToken;

  @override
  String? get serverAuthCode => null;
}

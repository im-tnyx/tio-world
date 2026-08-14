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

    test('signInWithGoogle returns SignInCancelled when Google Sign-In returns null', () async {
      final fakeClient = FakeSupabaseClient();
      final fakeGoogleSignIn = FakeGoogleSignIn(accountToReturn: null);
      final repo = SupabaseAuthSignInRepository(
        client: fakeClient,
        googleSignIn: fakeGoogleSignIn,
      );

      final result = await repo.signInWithGoogle();
      expect(result, isA<SignInCancelled>());
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
  });

  @override
  final User? currentUser;
  final AuthResponse? authResponseToReturn;
  final Object? exceptionToThrow;

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
    return authResponseToReturn ??
        AuthResponse(
          session: null,
          user: currentUser,
        );
  }
}

class FakeGoogleSignIn extends Fake implements GoogleSignIn {
  FakeGoogleSignIn({this.accountToReturn});

  final GoogleSignInAccount? accountToReturn;

  @override
  Future<GoogleSignInAccount?> signIn() async => accountToReturn;
}

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tio_feature_auth/src/data/google_sign_in_provider.dart';

class _FakeGoogleSignInAccount implements GoogleSignInAccount {
  @override
  final String displayName;
  @override
  final String email;
  @override
  final String id;
  @override
  final String photoUrl;
  @override
  final String? serverAuthCode = null;

  _FakeGoogleSignInAccount({
    required this.id,
    required this.email,
    required this.displayName,
    required this.photoUrl,
  });

  @override
  Future<GoogleSignInAuthentication> get authentication async => _FakeGoogleSignInAuthentication('mock_google_id_token');

  @override
  Future<Map<String, String>> get authHeaders async => {};

  @override
  Future<void> clearAuthCache() async {}
}

class _FakeGoogleSignInAuthentication implements GoogleSignInAuthentication {
  @override
  final String idToken;
  @override
  final String? accessToken = 'mock_access_token';
  @override
  final String? serverAuthCode = null;

  _FakeGoogleSignInAuthentication(this.idToken);
}

class _FakeGoogleSignIn extends GoogleSignIn {
  _FakeGoogleSignInAccount? accountToReturn;
  Exception? errorToThrow;

  @override
  Future<GoogleSignInAccount?> signIn() async {
    if (errorToThrow != null) throw errorToThrow!;
    return accountToReturn;
  }

  @override
  Future<GoogleSignInAccount?> signOut() async {
    return null;
  }
}

void main() {
  late _FakeGoogleSignIn fakeGoogleSignIn;
  late GoogleSignInProvider provider;

  setUp(() {
    fakeGoogleSignIn = _FakeGoogleSignIn();
    provider = GoogleSignInProvider(signIn: fakeGoogleSignIn);
  });

  test('signIn returns Success when valid account is chosen', () async {
    fakeGoogleSignIn.accountToReturn = _FakeGoogleSignInAccount(
      id: '123',
      email: 'test@example.com',
      displayName: 'Test',
      photoUrl: 'url',
    );

    final result = await provider.signIn();

    expect(result, isA<GoogleSignInSuccess>());
    expect((result as GoogleSignInSuccess).googleIdToken, 'mock_google_id_token');
  });

  test('signIn returns Cancelled when account is null', () async {
    fakeGoogleSignIn.accountToReturn = null;
    final result = await provider.signIn();
    expect(result, isA<GoogleSignInCancelled>());
  });
}

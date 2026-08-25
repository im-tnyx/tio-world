import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_auth/auth.dart';

class _FakeAuthSignInRepository implements AuthSignInRepository {
  SignInResult resultToReturn = const SignInCancelled();

  @override
  Future<SignInResult> signInWithGoogle() async => resultToReturn;

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async =>
      resultToReturn;

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async =>
      resultToReturn;

  @override
  Future<PasswordResetRequestResult> sendPasswordResetEmail(String email) async =>
      const PasswordResetRequestAccepted();

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async =>
      resultToReturn;
}

void main() {
  group('SignInWithGoogleUseCase', () {
    late _FakeAuthSignInRepository fakeRepository;
    late SignInWithGoogleUseCase useCase;

    setUp(() {
      fakeRepository = _FakeAuthSignInRepository();
      useCase = SignInWithGoogleUseCase(signInRepository: fakeRepository);
    });

    test('returns SignInSuccess when repository succeeds', () async {
      const session = AuthSession(userId: 'test-user-id', email: 'test@example.com');
      fakeRepository.resultToReturn = const SignInSuccess(session);

      final result = await useCase();

      expect(result, isA<SignInSuccess>());
      expect((result as SignInSuccess).session.userId, equals('test-user-id'));
    });

    test('returns SignInCancelled when user cancels', () async {
      fakeRepository.resultToReturn = const SignInCancelled();

      final result = await useCase();

      expect(result, isA<SignInCancelled>());
    });

    test('returns SignInFailure when repository encounters an error', () async {
      fakeRepository.resultToReturn = const SignInFailure('OAuth provider error');

      final result = await useCase();

      expect(result, isA<SignInFailure>());
      expect((result as SignInFailure).message, equals('OAuth provider error'));
    });
  });
}

import '../models/sign_in_result.dart';
import '../repositories/auth_sign_in_repository.dart';
import '../utils/canonical_email_identity.dart';

/// Use case for signing in with email and password.
class SignInWithEmailUseCase {
  const SignInWithEmailUseCase({required AuthSignInRepository signInRepository})
      : _signInRepository = signInRepository;

  final AuthSignInRepository _signInRepository;

  Future<SignInResult> call({
    required String email,
    required String password,
  }) {
    final canonicalEmail = canonicalEmailIdentity(email);
    if (canonicalEmail == null) {
      return Future.value(
        const SignInFailure(
          'Enter a valid email address.',
          code: 'invalid_email',
        ),
      );
    }

    return _signInRepository.signInWithEmailPassword(
      email: canonicalEmail,
      password: password,
    );
  }
}

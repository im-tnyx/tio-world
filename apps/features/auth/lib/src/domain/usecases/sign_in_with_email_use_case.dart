import '../models/sign_in_result.dart';
import '../repositories/auth_sign_in_repository.dart';

/// Use case for signing in with email and password.
class SignInWithEmailUseCase {
  const SignInWithEmailUseCase({required AuthSignInRepository signInRepository})
      : _signInRepository = signInRepository;

  final AuthSignInRepository _signInRepository;

  Future<SignInResult> call({
    required String email,
    required String password,
  }) =>
      _signInRepository.signInWithEmailPassword(
        email: email,
        password: password,
      );
}

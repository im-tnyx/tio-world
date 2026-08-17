import '../models/sign_in_result.dart';
import '../repositories/auth_sign_in_repository.dart';

/// Use case for registering a new user with email and password.
class SignUpWithEmailUseCase {
  const SignUpWithEmailUseCase({required AuthSignInRepository signInRepository})
      : _signInRepository = signInRepository;

  final AuthSignInRepository _signInRepository;

  Future<SignInResult> call({
    required String email,
    required String password,
    String? name,
  }) =>
      _signInRepository.signUpWithEmailPassword(
        email: email,
        password: password,
        name: name,
      );
}

import '../models/sign_in_result.dart';
import '../repositories/auth_sign_in_repository.dart';

/// Use case for sending a password reset email.
class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(
      {required AuthSignInRepository signInRepository})
      : _signInRepository = signInRepository;

  final AuthSignInRepository _signInRepository;

  Future<SignInResult> call(String email) =>
      _signInRepository.sendPasswordResetEmail(email);
}

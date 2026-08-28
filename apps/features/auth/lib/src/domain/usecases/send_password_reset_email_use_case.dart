import '../models/password_reset_request_result.dart';
import '../repositories/auth_sign_in_repository.dart';

/// Use case for requesting a password reset email.
class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(
      {required AuthSignInRepository signInRepository})
      : _signInRepository = signInRepository;

  final AuthSignInRepository _signInRepository;

  Future<PasswordResetRequestResult> call(String email) =>
      _signInRepository.sendPasswordResetEmail(email);
}

import '../models/sign_in_result.dart';
import '../repositories/auth_sign_in_repository.dart';

/// Clean use case for authenticating with Google.
///
/// Current production implementation routes through [AuthSignInRepository].
class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase({
    required AuthSignInRepository signInRepository,
  }) : _signInRepository = signInRepository;

  final AuthSignInRepository _signInRepository;

  Future<SignInResult> call() => _signInRepository.signInWithGoogle();
}

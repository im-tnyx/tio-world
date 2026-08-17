import '../models/google_sign_in_intent.dart';
import '../models/sign_in_result.dart';
import '../repositories/auth_sign_in_repository.dart';

/// Clean use case for authenticating with Google.
///
/// Returning-user Login is the safe default. Explicit account-creation flows
/// must opt into [GoogleSignInIntent.signupOrExisting].
class SignInWithGoogleUseCase {
  const SignInWithGoogleUseCase({
    required AuthSignInRepository signInRepository,
  }) : _signInRepository = signInRepository;

  final AuthSignInRepository _signInRepository;

  Future<SignInResult> call({
    GoogleSignInIntent intent = GoogleSignInIntent.existingAccountOnly,
  }) {
    final repository = _signInRepository;
    if (repository is GoogleSignInIntentRepository) {
      return repository.signInWithGoogleForIntent(intent: intent);
    }
    return repository.signInWithGoogle();
  }
}

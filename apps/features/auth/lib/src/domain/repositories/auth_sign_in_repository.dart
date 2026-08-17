import '../models/google_sign_in_intent.dart';
import '../models/sign_in_result.dart';

/// Repository contract for signing in users.
///
/// Current production implementation delegates to Supabase Auth.
/// Future custom backend implementation can implement this same contract.
abstract interface class AuthSignInRepository {
  /// Authenticates using Google according to the product [intent].
  ///
  /// Returning-user Login must pass [GoogleSignInIntent.existingAccountOnly]
  /// so an unknown Google identity cannot silently create a Tio account.
  /// Explicit onboarding/account-creation flows may pass
  /// [GoogleSignInIntent.signupOrExisting].
  Future<SignInResult> signInWithGoogle({
    required GoogleSignInIntent intent,
  });

  /// Signs in using email and password.
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  });

  /// Signs up a new user using email and password.
  /// [name] is stored in user metadata and displayed in the UI.
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  });

  /// Sends a password reset email to [email].
  /// Returns [SignInSuccess] with an empty session on success,
  /// or [SignInFailure] on error.
  Future<SignInResult> sendPasswordResetEmail(String email);

  /// Signs in using email OTP / Magic link.
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  });
}

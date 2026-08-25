import '../models/google_sign_in_intent.dart';
import '../models/password_reset_request_result.dart';
import '../models/sign_in_result.dart';

/// Repository contract for signing in users.
///
/// Current production implementation delegates to Supabase Auth.
/// Future custom backend implementation can implement this same contract.
abstract interface class AuthSignInRepository {
  /// Signs in using Google OAuth / ID token exchange.
  ///
  /// The legacy/default contract is returning-user safe. Production
  /// repositories that support explicit signup intent should additionally
  /// implement [GoogleSignInIntentRepository].
  Future<SignInResult> signInWithGoogle();

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

  /// Requests a password-recovery email for [email].
  ///
  /// An accepted request does not establish an authenticated session and does
  /// not prove that an account exists or that an email was delivered.
  Future<PasswordResetRequestResult> sendPasswordResetEmail(String email);

  /// Signs in using email OTP / Magic link.
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  });
}

/// Optional capability for repositories that distinguish returning-user Login
/// from explicit signup/onboarding Google authentication.
abstract interface class GoogleSignInIntentRepository {
  Future<SignInResult> signInWithGoogleForIntent({
    required GoogleSignInIntent intent,
  });
}

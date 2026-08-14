import '../models/sign_in_result.dart';

/// Repository contract for signing in users.
///
/// Current production implementation delegates to Supabase Auth.
/// Future custom backend implementation can implement this same contract.
abstract interface class AuthSignInRepository {
  /// Signs in using Google OAuth / ID token exchange.
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

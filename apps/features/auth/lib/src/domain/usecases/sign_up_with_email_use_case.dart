import 'dart:async';

import '../models/sign_in_result.dart';
import '../repositories/auth_sign_in_repository.dart';
import '../utils/canonical_email_identity.dart';

/// Use case for registering a new user with email and password.
class SignUpWithEmailUseCase {
  const SignUpWithEmailUseCase({
    required AuthSignInRepository signInRepository,
    Duration timeout = const Duration(seconds: 15),
  })  : _signInRepository = signInRepository,
        _timeout = timeout;

  static const _neutralPendingMessage =
      'Check your email to continue. If you already have a Tio account, '
      'use Log In or Forgot Password.';

  final AuthSignInRepository _signInRepository;
  final Duration _timeout;

  Future<SignInResult> call({
    required String email,
    required String password,
    String? name,
  }) async {
    final canonicalEmail = canonicalEmailIdentity(email);
    if (canonicalEmail == null) {
      return const SignInFailure(
        'Enter a valid email address.',
        code: 'invalid_email',
      );
    }

    try {
      final result = await _signInRepository
          .signUpWithEmailPassword(
            email: canonicalEmail,
            password: password,
            name: name,
          )
          .timeout(_timeout);

      if (result is SignInFailure &&
          (result.code == 'email_confirmation_required' ||
              result.code == 'user_already_exists')) {
        // Supabase can deliberately obfuscate existing-account Signup responses.
        // Keep the same user-visible outcome for a fresh pending confirmation
        // and an obfuscated duplicate so Signup cannot be used as an account
        // existence oracle.
        return const SignInFailure(
          _neutralPendingMessage,
          code: 'email_confirmation_required',
        );
      }

      return result;
    } on TimeoutException {
      return const SignInFailure(
        'Email sign up took too long. Please try again.',
        code: 'email_signup_timeout',
      );
    }
  }
}

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/models/sign_in_result.dart';
import '../../domain/repositories/auth_sign_in_repository.dart';

/// Supabase-backed implementation of [AuthSignInRepository].
///
/// Authenticates users directly with Supabase GoTrue and establishes
/// an authenticated session.
class SupabaseAuthSignInRepository implements AuthSignInRepository {
  SupabaseAuthSignInRepository({
    required SupabaseClient client,
    GoogleSignIn? googleSignIn,
    String? serverClientId,
  })  : _client = client,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              serverClientId: serverClientId ??
                  const String.fromEnvironment(
                    'GOOGLE_WEB_CLIENT_ID',
                    defaultValue:
                        '218403286180-2047ibc6i5r6tb2kftoq4lu6220kl8d9.apps.googleusercontent.com',
                  ),
            );

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;

  @override
  Future<SignInResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return const SignInCancelled();
      }

      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        // Fallback to Supabase OAuth browser flow if native ID token is unavailable
        final success = await _client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: 'tio://login-callback',
        );
        if (!success) {
          return const SignInCancelled();
        }
        final user = _client.auth.currentUser;
        if (user != null) {
          return SignInSuccess(_mapUser(user));
        }
        return const SignInCancelled();
      }

      final response = await _client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      final user = response.user ?? _client.auth.currentUser;
      if (user == null) {
        return const SignInFailure('Failed to obtain authenticated Supabase user.');
      }

      return SignInSuccess(_mapUser(user));
    } on AuthException catch (e) {
      return SignInFailure(e.message, code: e.statusCode);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('canceled') ||
          errorStr.contains('cancelled') ||
          errorStr.contains('SIGN_IN_CANCELLED')) {
        return const SignInCancelled();
      }
      return SignInFailure(errorStr);
    }
  }

  @override
  Future<SignInResult> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user ?? _client.auth.currentUser;
      if (user == null) {
        return const SignInFailure('Sign in failed: user not returned.');
      }
      return SignInSuccess(_mapUser(user));
    } on AuthException catch (e) {
      return SignInFailure(e.message, code: e.statusCode);
    } catch (e) {
      return SignInFailure(e.toString());
    }
  }

  @override
  Future<SignInResult> signUpWithEmailPassword({
    required String email,
    required String password,
    String? name,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          if (name != null && name.trim().isNotEmpty) 'full_name': name.trim(),
        },
      );
      final user = response.user ?? _client.auth.currentUser;
      if (user == null) {
        return const SignInFailure('Sign up failed: user not returned.');
      }
      return SignInSuccess(_mapUser(user));
    } on AuthException catch (e) {
      return SignInFailure(e.message, code: e.statusCode);
    } catch (e) {
      return SignInFailure(e.toString());
    }
  }

  @override
  Future<SignInResult> sendPasswordResetEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email.trim());
      // Return a synthetic empty session to signal success — no user session created.
      return const SignInSuccess(
        AuthSession(userId: '', email: null, displayName: null),
      );
    } on AuthException catch (e) {
      return SignInFailure(e.message, code: e.statusCode);
    } catch (e) {
      return SignInFailure(e.toString());
    }
  }

  @override
  Future<SignInResult> signInWithOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _client.auth.verifyOTP(
        email: email.trim(),
        token: token.trim(),
        type: OtpType.magiclink,
      );
      final user = response.user ?? _client.auth.currentUser;
      if (user == null) {
        return const SignInFailure('OTP verification failed.');
      }
      return SignInSuccess(_mapUser(user));
    } on AuthException catch (e) {
      return SignInFailure(e.message, code: e.statusCode);
    } catch (e) {
      return SignInFailure(e.toString());
    }
  }

  AuthSession _mapUser(User user) {
    final metadata = user.userMetadata ?? const {};
    final displayName = metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        metadata['display_name'] as String?;
    final photoUrl = metadata['avatar_url'] as String? ??
        metadata['picture'] as String?;

    return AuthSession(
      userId: user.id,
      email: user.email,
      phone: user.phone,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}

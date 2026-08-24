import 'dart:async';
import 'dart:developer' as developer;

import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/models/google_sign_in_intent.dart';
import '../../domain/models/sign_in_result.dart';
import '../../domain/repositories/auth_sign_in_repository.dart';
import '../../domain/repositories/user_device_repository.dart';
import '../google_login_admission_checker.dart';

typedef GoogleProfileSyncCallback = Future<void> Function({
  required User user,
  required AuthSession session,
  required bool importProviderPhoto,
});

/// Supabase-backed implementation of [AuthSignInRepository].
///
/// Authenticates users directly with Supabase GoTrue and establishes
/// an authenticated session.
class SupabaseAuthSignInRepository
    implements AuthSignInRepository, GoogleSignInIntentRepository {
  SupabaseAuthSignInRepository({
    required SupabaseClient client,
    GoogleSignIn? googleSignIn,
    String? serverClientId,
    UserDeviceRepository? userDeviceRepository,
    GoogleLoginAdmissionChecker? googleLoginAdmissionChecker,
    GoogleProfileSyncCallback? googleProfileSyncCallback,
    Duration googleAccountSelectionTimeout = const Duration(seconds: 30),
    Duration googleCredentialTimeout = const Duration(seconds: 15),
    Duration googleAdmissionTimeout = const Duration(seconds: 8),
    Duration googleSupabaseExchangeTimeout = const Duration(seconds: 15),
  })  : _client = client,
        _userDeviceRepository = userDeviceRepository,
        _googleLoginAdmissionChecker = googleLoginAdmissionChecker ??
            SupabaseGoogleLoginAdmissionChecker(client: client).call,
        _googleProfileSyncCallback = googleProfileSyncCallback,
        _googleAccountSelectionTimeout = googleAccountSelectionTimeout,
        _googleCredentialTimeout = googleCredentialTimeout,
        _googleAdmissionTimeout = googleAdmissionTimeout,
        _googleSupabaseExchangeTimeout = googleSupabaseExchangeTimeout,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              scopes: const ['email', 'profile'],
              serverClientId: serverClientId ??
                  const String.fromEnvironment(
                    'GOOGLE_WEB_CLIENT_ID',
                    defaultValue:
                        '218403286180-2047ibc6i5r6tb2kftoq4lu6220kl8d9.apps.googleusercontent.com',
                  ),
            );

  final SupabaseClient _client;
  final GoogleSignIn _googleSignIn;
  final UserDeviceRepository? _userDeviceRepository;
  final GoogleLoginAdmissionChecker _googleLoginAdmissionChecker;
  final GoogleProfileSyncCallback? _googleProfileSyncCallback;
  final Duration _googleAccountSelectionTimeout;
  final Duration _googleCredentialTimeout;
  final Duration _googleAdmissionTimeout;
  final Duration _googleSupabaseExchangeTimeout;

  @override
  Future<SignInResult> signInWithGoogle() => signInWithGoogleForIntent(
        intent: GoogleSignInIntent.existingAccountOnly,
      );

  @override
  Future<SignInResult> signInWithGoogleForIntent({
    required GoogleSignInIntent intent,
  }) async {
    try {
      developer.log('[GoogleAuth] clearing cached Google account selection');
      try {
        await _googleSignIn
            .signOut()
            .timeout(_googleAccountSelectionTimeout);
      } on TimeoutException catch (error, stackTrace) {
        developer.log(
          '[GoogleAuth] cached Google account reset timed out',
          error: error,
          stackTrace: stackTrace,
        );
        return const SignInFailure(
          'Google account selection could not be prepared in time. Please try again.',
          code: 'google_account_reset_timeout',
        );
      } catch (error, stackTrace) {
        developer.log(
          '[GoogleAuth] cached Google account reset failed',
          error: error,
          stackTrace: stackTrace,
        );
        return const SignInFailure(
          'Could not open the Google account chooser. Please try again.',
          code: 'google_account_reset_failed',
        );
      }
      developer.log('[GoogleAuth] cached Google account selection cleared');

      developer.log('[GoogleAuth] account selection started');
      GoogleSignInAccount? googleUser;
      try {
        googleUser = await _googleSignIn
            .signIn()
            .timeout(_googleAccountSelectionTimeout);
      } on TimeoutException catch (error, stackTrace) {
        developer.log(
          '[GoogleAuth] account selection timed out',
          error: error,
          stackTrace: stackTrace,
        );
        return const SignInFailure(
          'Google sign-in took too long before account selection completed. Please try again.',
          code: 'google_account_selection_timeout',
        );
      }

      if (googleUser == null) {
        developer.log('[GoogleAuth] account selection cancelled');
        return const SignInCancelled();
      }
      developer.log('[GoogleAuth] account selected');

      developer.log('[GoogleAuth] credential read started');
      GoogleSignInAuthentication googleAuth;
      try {
        googleAuth = await googleUser.authentication
            .timeout(_googleCredentialTimeout);
      } on TimeoutException catch (error, stackTrace) {
        developer.log(
          '[GoogleAuth] credential read timed out',
          error: error,
          stackTrace: stackTrace,
        );
        return const SignInFailure(
          'Google sign-in took too long while reading credentials. Please try again.',
          code: 'google_credential_timeout',
        );
      }
      developer.log('[GoogleAuth] credential read completed');

      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null || idToken.isEmpty) {
        if (intent == GoogleSignInIntent.existingAccountOnly) {
          developer.log(
            '[GoogleAuth] native ID token unavailable for existing-account admission',
          );
          return const SignInFailure(
            'Tio could not verify this Google account. Please try again.',
            code: 'google_login_admission_token_unavailable',
          );
        }

        developer.log(
          '[GoogleAuth] native ID token unavailable; signup-capable OAuth fallback started',
        );
        bool success;
        try {
          success = await _client.auth
              .signInWithOAuth(
                OAuthProvider.google,
                redirectTo: 'tio://login-callback',
                queryParams: const {'prompt': 'select_account'},
              )
              .timeout(_googleSupabaseExchangeTimeout);
        } on TimeoutException catch (error, stackTrace) {
          developer.log(
            '[GoogleAuth] OAuth fallback timed out',
            error: error,
            stackTrace: stackTrace,
          );
          return const SignInFailure(
            'Tio could not finish Google sign-in in time. Please try again.',
            code: 'google_supabase_exchange_timeout',
          );
        }
        if (!success) {
          return const SignInCancelled();
        }
        final user = _client.auth.currentUser;
        if (user != null) {
          developer.log('[GoogleAuth] OAuth fallback session established');
          final session = _mapUser(user);
          _startDeviceSync();
          // Without a native ID token we cannot classify fresh-vs-returning
          // before account creation. Be conservative and never import a
          // provider avatar on this fallback path.
          _startGoogleProfileSync(user: user, session: session);
          return SignInSuccess(session);
        }
        return const SignInCancelled();
      }

      Future<GoogleLoginAdmissionDecision?>? signupAccountDecision;
      if (intent == GoogleSignInIntent.signupOrExisting) {
        // Start fresh-vs-returning classification before the Supabase exchange,
        // but do not await it on the authentication critical path. Profile
        // enrichment can consume the result later in the background.
        signupAccountDecision =
            _classifyGoogleAccountForProfileBootstrap(idToken);
      }

      if (intent == GoogleSignInIntent.existingAccountOnly) {
        developer.log('[GoogleAuth] existing-account admission started');
        GoogleLoginAdmissionDecision admissionDecision;
        try {
          admissionDecision = await _googleLoginAdmissionChecker(idToken)
              .timeout(_googleAdmissionTimeout);
        } on TimeoutException catch (error, stackTrace) {
          developer.log(
            '[GoogleAuth] existing-account admission timed out',
            error: error,
            stackTrace: stackTrace,
          );
          return const SignInFailure(
            'Tio could not verify your account in time. Please try again.',
            code: 'google_login_admission_timeout',
          );
        } catch (error, stackTrace) {
          developer.log(
            '[GoogleAuth] existing-account admission failed',
            error: error,
            stackTrace: stackTrace,
          );
          return const SignInFailure(
            'Tio could not verify your account right now. Please try again.',
            code: 'google_login_admission_failed',
          );
        }

        if (admissionDecision == GoogleLoginAdmissionDecision.noAccount) {
          developer.log('[GoogleAuth] existing-account admission denied');
          return const SignInFailure(
            'No Tio account found for this Google account.\n'
            'Create a Tio account first to continue.',
            code: 'google_account_not_found',
          );
        }
        developer.log('[GoogleAuth] existing-account admission allowed');
      }

      developer.log('[GoogleAuth] Supabase ID-token exchange started');
      AuthResponse response;
      try {
        response = await _client.auth
            .signInWithIdToken(
              provider: OAuthProvider.google,
              idToken: idToken,
              accessToken: accessToken,
            )
            .timeout(_googleSupabaseExchangeTimeout);
      } on TimeoutException catch (error, stackTrace) {
        developer.log(
          '[GoogleAuth] Supabase ID-token exchange timed out',
          error: error,
          stackTrace: stackTrace,
        );
        return const SignInFailure(
          'Tio could not finish Google sign-in in time. Please try again.',
          code: 'google_supabase_exchange_timeout',
        );
      }
      developer.log('[GoogleAuth] Supabase ID-token exchange completed');

      final user = response.user ?? _client.auth.currentUser;
      if (user == null) {
        return const SignInFailure('Failed to obtain authenticated Supabase user.');
      }

      final session = _mapUser(user);

      // The authenticated Supabase session is the critical-path success signal.
      // Device/profile synchronization is secondary and must not keep the login
      // action loading if the network or a downstream table is slow/unavailable.
      _startDeviceSync();
      _startGoogleProfileSync(
        user: user,
        session: session,
        accountDecision: signupAccountDecision,
      );

      developer.log('[GoogleAuth] sign-in completed successfully');
      return SignInSuccess(session);
    } on AuthException catch (e) {
      developer.log('[GoogleAuth] Supabase auth failure', error: e);
      return SignInFailure(e.message, code: e.statusCode);
    } catch (e, stackTrace) {
      developer.log(
        '[GoogleAuth] unexpected sign-in failure',
        error: e,
        stackTrace: stackTrace,
      );
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
      _startDeviceSync();
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
      final normalizedEmail = email.trim().toLowerCase();
      final response = await _client.auth.signUp(
        email: normalizedEmail,
        password: password,
        data: {
          if (name != null && name.trim().isNotEmpty) 'full_name': name.trim(),
        },
      );
      final user = response.user;
      if (user == null) {
        return const SignInFailure('Sign up failed: user not returned.');
      }
      // If user already exists, Supabase returns user with empty identities list.
      if (user.identities != null && user.identities!.isEmpty) {
        return const SignInFailure(
          'This email is already registered. Please log in to continue.',
          code: 'user_already_exists',
        );
      }

      // With Email confirmation enabled Supabase can create the user without
      // establishing a session. That is a successful account creation, but it
      // is not authenticated success and must not enter onboarding yet.
      final authSession = response.session;
      if (authSession == null) {
        return SignInFailure(
          'Check $normalizedEmail to confirm your email before signing in.',
          code: 'email_confirmation_required',
        );
      }

      _startDeviceSync();
      return SignInSuccess(_mapUser(authSession.user));
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered') ||
          e.message.toLowerCase().contains('already in use') ||
          e.message.toLowerCase().contains('user already exists')) {
        return const SignInFailure(
          'This email is already registered. Please log in to continue.',
          code: 'user_already_exists',
        );
      }
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
      _startDeviceSync();
      return SignInSuccess(_mapUser(user));
    } on AuthException catch (e) {
      return SignInFailure(e.message, code: e.statusCode);
    } catch (e) {
      return SignInFailure(e.toString());
    }
  }

  void _startDeviceSync() {
    final repository = _userDeviceRepository;
    if (repository == null) return;

    unawaited(
      repository
          .syncCurrentDevice()
          .catchError((Object error, StackTrace stackTrace) {
        developer.log(
          'Failed to sync authenticated user device',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  Future<GoogleLoginAdmissionDecision?>
      _classifyGoogleAccountForProfileBootstrap(String idToken) async {
    try {
      developer.log('[GoogleAuth] signup profile classification started');
      final decision = await _googleLoginAdmissionChecker(idToken)
          .timeout(_googleAdmissionTimeout);
      developer.log(
        '[GoogleAuth] signup profile classification completed: ${decision.name}',
      );
      return decision;
    } on TimeoutException catch (error, stackTrace) {
      developer.log(
        '[GoogleAuth] signup profile classification timed out; avatar import skipped',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    } catch (error, stackTrace) {
      developer.log(
        '[GoogleAuth] signup profile classification failed; avatar import skipped',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  void _startGoogleProfileSync({
    required User user,
    required AuthSession session,
    Future<GoogleLoginAdmissionDecision?>? accountDecision,
  }) {
    unawaited(
      _syncGoogleProfile(
        user: user,
        session: session,
        accountDecision: accountDecision,
      ),
    );
  }

  Future<void> _syncGoogleProfile({
    required User user,
    required AuthSession session,
    Future<GoogleLoginAdmissionDecision?>? accountDecision,
  }) async {
    try {
      final decision = accountDecision == null ? null : await accountDecision;
      final importProviderPhoto =
          decision == GoogleLoginAdmissionDecision.noAccount;
      final callback = _googleProfileSyncCallback;
      if (callback != null) {
        await callback(
          user: user,
          session: session,
          importProviderPhoto: importProviderPhoto,
        );
        return;
      }

      await _persistGoogleProfile(
        user: user,
        session: session,
        importProviderPhoto: importProviderPhoto,
      );
    } catch (e, stackTrace) {
      developer.log(
        'Failed to auto-sync Google user profile',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _persistGoogleProfile({
    required User user,
    required AuthSession session,
    required bool importProviderPhoto,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final updatedRows = await _client
        .from('users')
        .update(
          {
            // Profile Name is owned exclusively by public.user_profiles.name.
            // Auth/provider display metadata is never persisted into users.
            // Auth contact projection is database-owned by the auth.users
            // reconciliation trigger, so this enrichment owns only Account
            // activity and first-account provider avatar import.
            if (importProviderPhoto &&
                session.photoUrl != null &&
                session.photoUrl!.isNotEmpty)
              'avatar_url': session.photoUrl,
            'last_active_at': nowIso,
            'updated_at': nowIso,
          },
        )
        .eq('id', user.id)
        .select('id');

    if (updatedRows.isEmpty) {
      throw StateError(
        'Account root is missing for the authenticated Google user.',
      );
    }
  }

  AuthSession _mapUser(User user) {
    final metadata = user.userMetadata ?? const {};
    final displayName = metadata['full_name'] as String? ??
        metadata['name'] as String? ??
        metadata['display_name'] as String?;
    final photoUrl =
        metadata['avatar_url'] as String? ?? metadata['picture'] as String?;

    return AuthSession(
      userId: user.id,
      email: user.email,
      phone: user.phone,
      isEmailVerified: user.emailConfirmedAt != null,
      isPhoneVerified: user.phoneConfirmedAt != null,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}

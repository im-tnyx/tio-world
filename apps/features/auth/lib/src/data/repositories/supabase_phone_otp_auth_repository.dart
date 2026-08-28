import 'dart:async';
import 'dart:developer' as developer;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/models/auth_session.dart';
import '../../domain/models/phone_otp_intent.dart';
import '../../domain/models/phone_otp_request_result.dart';
import '../../domain/models/sign_in_result.dart';
import '../../domain/repositories/phone_otp_auth_repository.dart';
import '../../domain/repositories/user_device_repository.dart';

typedef PhoneOtpRequestSender = Future<void> Function({
  required String phone,
  required bool shouldCreateUser,
});

typedef PhoneOtpVerifier = Future<AuthResponse> Function({
  required String phone,
  required String token,
});

/// Supabase-backed passwordless Phone OTP capability.
///
/// This repository expects canonical E.164 input. It never writes application
/// verification timestamps; Supabase Auth + trusted DB reconciliation own them.
final class SupabasePhoneOtpAuthRepository implements PhoneOtpAuthRepository {
  SupabasePhoneOtpAuthRepository({
    required SupabaseClient client,
    UserDeviceRepository? userDeviceRepository,
    PhoneOtpRequestSender? requestSender,
    PhoneOtpVerifier? verifier,
  })  : _client = client,
        _userDeviceRepository = userDeviceRepository,
        _requestSender = requestSender,
        _verifier = verifier;

  final SupabaseClient _client;
  final UserDeviceRepository? _userDeviceRepository;
  final PhoneOtpRequestSender? _requestSender;
  final PhoneOtpVerifier? _verifier;

  static final RegExp _canonicalE164 = RegExp(r'^\+[1-9][0-9]{7,14}$');

  @override
  Future<PhoneOtpRequestResult> requestCode({
    required String phone,
    required PhoneOtpIntent intent,
  }) {
    return _sendCode(
      phone: phone,
      intent: intent,
      isResend: false,
    );
  }

  @override
  Future<PhoneOtpRequestResult> resendCode({
    required String phone,
    required PhoneOtpIntent intent,
  }) {
    return _sendCode(
      phone: phone,
      intent: intent,
      isResend: true,
    );
  }

  Future<PhoneOtpRequestResult> _sendCode({
    required String phone,
    required PhoneOtpIntent intent,
    required bool isResend,
  }) async {
    if (!_canonicalE164.hasMatch(phone)) {
      return const PhoneOtpRequestFailure(
        'Enter a valid mobile number.',
        code: 'invalid_phone',
      );
    }

    try {
      final sender = _requestSender;
      if (sender != null) {
        await sender(
          phone: phone,
          shouldCreateUser: intent.shouldCreateUser,
        );
      } else {
        await _client.auth.signInWithOtp(
          phone: phone,
          shouldCreateUser: intent.shouldCreateUser,
          channel: OtpChannel.sms,
        );
      }

      return PhoneOtpCodeSent(phone);
    } on AuthException catch (error, stackTrace) {
      developer.log(
        isResend ? 'Phone OTP resend failed' : 'Phone OTP request failed',
        error: error,
        stackTrace: stackTrace,
      );
      return PhoneOtpRequestFailure(
        isResend
            ? 'Could not resend the verification code. Please try again.'
            : 'Could not send the verification code. Please try again.',
        code: isResend ? 'phone_otp_resend_failed' : 'phone_otp_request_failed',
      );
    } catch (error, stackTrace) {
      developer.log(
        isResend
            ? 'Unexpected Phone OTP resend failure'
            : 'Unexpected Phone OTP request failure',
        error: error,
        stackTrace: stackTrace,
      );
      return PhoneOtpRequestFailure(
        isResend
            ? 'Could not resend the verification code. Please try again.'
            : 'Could not send the verification code. Please try again.',
        code: isResend ? 'phone_otp_resend_failed' : 'phone_otp_request_failed',
      );
    }
  }

  @override
  Future<SignInResult> verifyCode({
    required String phone,
    required String token,
  }) async {
    if (!_canonicalE164.hasMatch(phone)) {
      return const SignInFailure(
        'Enter a valid mobile number.',
        code: 'invalid_phone',
      );
    }

    final normalizedToken = token.trim();
    if (normalizedToken.isEmpty) {
      return const SignInFailure(
        'Enter the verification code.',
        code: 'invalid_otp',
      );
    }

    try {
      final verifier = _verifier;
      final response = verifier != null
          ? await verifier(phone: phone, token: normalizedToken)
          : await _client.auth.verifyOTP(
              phone: phone,
              token: normalizedToken,
              type: OtpType.sms,
            );

      final session = response.session;
      if (session == null) {
        return const SignInFailure(
          'Tio could not establish an authenticated session. Please try again.',
          code: 'phone_otp_session_missing',
        );
      }

      final sessionUser = session.user;
      final responseUser = response.user;
      if (responseUser != null && responseUser.id != sessionUser.id) {
        return const SignInFailure(
          'Tio could not safely match this mobile verification to an account.',
          code: 'phone_otp_identity_mismatch',
        );
      }

      if (sessionUser.phone?.trim() != phone ||
          sessionUser.phoneConfirmedAt == null) {
        return const SignInFailure(
          'Tio could not confirm this mobile number. Please request a new code.',
          code: 'phone_otp_identity_mismatch',
        );
      }

      _startDeviceSync();
      return SignInSuccess(_mapUser(sessionUser));
    } on AuthException catch (error, stackTrace) {
      developer.log(
        'Phone OTP verification failed',
        error: error,
        stackTrace: stackTrace,
      );
      return const SignInFailure(
        'The verification code could not be verified. Please try again.',
        code: 'phone_otp_verify_failed',
      );
    } catch (error, stackTrace) {
      developer.log(
        'Unexpected Phone OTP verification failure',
        error: error,
        stackTrace: stackTrace,
      );
      return const SignInFailure(
        'The verification code could not be verified. Please try again.',
        code: 'phone_otp_verify_failed',
      );
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
          'Failed to sync device after Phone OTP authentication',
          error: error,
          stackTrace: stackTrace,
        );
      }),
    );
  }

  AuthSession _mapUser(User user) {
    final metadata = user.userMetadata ?? const <String, dynamic>{};
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

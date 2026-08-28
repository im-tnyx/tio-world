import 'dart:async';

import 'package:tio_shared/shared.dart';

import '../models/sign_in_result.dart';
import '../repositories/phone_otp_auth_repository.dart';

/// Verifies a Phone OTP and requires a real authenticated Supabase session.
final class VerifyPhoneOtpUseCase {
  const VerifyPhoneOtpUseCase({
    required PhoneOtpAuthRepository repository,
    Duration timeout = const Duration(seconds: 15),
  })  : _repository = repository,
        _timeout = timeout;

  final PhoneOtpAuthRepository _repository;
  final Duration _timeout;

  Future<SignInResult> call({
    required String phone,
    required String token,
  }) async {
    final canonicalPhone = _canonicalPhone(phone);
    if (canonicalPhone == null) {
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
      return await _repository
          .verifyCode(phone: canonicalPhone, token: normalizedToken)
          .timeout(_timeout);
    } on TimeoutException {
      return const SignInFailure(
        'Verifying the code took too long. Please try again.',
        code: 'phone_otp_verify_timeout',
      );
    }
  }
}

String? _canonicalPhone(String phone) {
  try {
    final normalized = normalizePhoneNumberE164(phone);
    return normalized.isEmpty ? null : normalized;
  } on ArgumentError {
    return null;
  }
}

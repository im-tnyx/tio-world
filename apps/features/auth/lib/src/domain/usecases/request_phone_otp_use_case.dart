import 'dart:async';

import 'package:tio_shared/shared.dart';

import '../models/phone_otp_intent.dart';
import '../models/phone_otp_request_result.dart';
import '../repositories/phone_otp_auth_repository.dart';

/// Requests a real Supabase passwordless Phone OTP.
final class RequestPhoneOtpUseCase {
  const RequestPhoneOtpUseCase({
    required PhoneOtpAuthRepository repository,
    Duration timeout = const Duration(seconds: 15),
  })  : _repository = repository,
        _timeout = timeout;

  final PhoneOtpAuthRepository _repository;
  final Duration _timeout;

  Future<PhoneOtpRequestResult> call({
    required String phone,
    required PhoneOtpIntent intent,
  }) async {
    final canonicalPhone = _canonicalPhone(phone);
    if (canonicalPhone == null) {
      return const PhoneOtpRequestFailure(
        'Enter a valid mobile number.',
        code: 'invalid_phone',
      );
    }

    try {
      return await _repository
          .requestCode(phone: canonicalPhone, intent: intent)
          .timeout(_timeout);
    } on TimeoutException {
      return const PhoneOtpRequestFailure(
        'Sending the verification code took too long. Please try again.',
        code: 'phone_otp_request_timeout',
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

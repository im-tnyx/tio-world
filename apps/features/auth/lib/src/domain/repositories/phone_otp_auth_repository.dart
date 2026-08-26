import '../models/phone_otp_intent.dart';
import '../models/phone_otp_request_result.dart';
import '../models/sign_in_result.dart';

/// Passwordless Phone OTP boundary.
///
/// Callers pass canonical E.164 phone values. Request/resend only means that
/// Supabase accepted delivery; [verifyCode] is the only authenticated result.
abstract interface class PhoneOtpAuthRepository {
  Future<PhoneOtpRequestResult> requestCode({
    required String phone,
    required PhoneOtpIntent intent,
  });

  Future<PhoneOtpRequestResult> resendCode({
    required String phone,
    required PhoneOtpIntent intent,
  });

  Future<SignInResult> verifyCode({
    required String phone,
    required String token,
  });
}

/// Result of requesting or resending a passwordless Phone OTP.
///
/// A sent code is intentionally not an authenticated success state.
sealed class PhoneOtpRequestResult {
  const PhoneOtpRequestResult();
}

/// Supabase accepted the OTP request for [canonicalPhone].
final class PhoneOtpCodeSent extends PhoneOtpRequestResult {
  const PhoneOtpCodeSent(this.canonicalPhone);

  final String canonicalPhone;

  @override
  bool operator ==(Object other) =>
      other is PhoneOtpCodeSent && other.canonicalPhone == canonicalPhone;

  @override
  int get hashCode => canonicalPhone.hashCode;
}

/// The Phone OTP request/resend failed before authentication.
final class PhoneOtpRequestFailure extends PhoneOtpRequestResult {
  const PhoneOtpRequestFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  bool operator ==(Object other) =>
      other is PhoneOtpRequestFailure &&
      other.message == message &&
      other.code == code;

  @override
  int get hashCode => Object.hash(message, code);
}

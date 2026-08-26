/// Distinguishes Phone OTP account creation from returning-user Login.
enum PhoneOtpIntent {
  signup,
  login;

  bool get shouldCreateUser => this == PhoneOtpIntent.signup;
}

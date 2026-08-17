/// Product intent for a Google authentication attempt.
///
/// [existingAccountOnly] is used by returning-user Login surfaces and must not
/// create a new Tio account when the selected Google identity is unknown.
///
/// [signupOrExisting] is used by explicit account-creation/onboarding flows,
/// where selecting an unknown Google identity may create a new account.
enum GoogleSignInIntent {
  existingAccountOnly,
  signupOrExisting,
}

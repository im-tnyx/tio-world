/// Returns whether the standalone Mobile onboarding step should be part of the
/// active onboarding plan.
///
/// A verified phone-auth identity already owns a mobile number, so asking for
/// the same value again is redundant. Email/Google/signed-out flows have no
/// provider-verified phone and therefore keep the optional Mobile step.
bool shouldIncludeMobileOnboarding(String? authenticatedPhone) {
  return authenticatedPhone == null || authenticatedPhone.trim().isEmpty;
}

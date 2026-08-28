/// Optional capability for resending an Email Signup confirmation request.
///
/// This stays separate from normal sign-in so pending Signup remains an
/// unauthenticated state until Supabase Auth confirms ownership.
abstract interface class EmailSignupConfirmationRepository {
  Future<void> resendSignupConfirmation({required String email});
}

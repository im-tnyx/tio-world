/// Durable backend onboarding completion state for the current authenticated user.
enum RemoteOnboardingCompletionState {
  /// No application-user row exists yet for the authenticated identity.
  uninitialized,

  /// The application-user exists but onboarding is not yet completed.
  incomplete,

  /// The backend has published onboarding completion.
  completed,
}

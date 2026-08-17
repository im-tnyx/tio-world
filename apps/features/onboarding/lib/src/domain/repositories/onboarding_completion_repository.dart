import '../models/remote_onboarding_completion_state.dart';

/// Durable backend boundary for onboarding completion of the current auth user.
abstract interface class OnboardingCompletionRepository {
  /// Reads the current authenticated user's backend onboarding state.
  ///
  /// A missing application-user row is represented as
  /// [RemoteOnboardingCompletionState.uninitialized]. Authentication or backend
  /// failures are surfaced as errors and must not be reclassified as a new user.
  Future<RemoteOnboardingCompletionState> readCurrent();

  /// Publishes backend onboarding completion for the current authenticated user.
  ///
  /// Implementations must fail when there is no authenticated user or when the
  /// application-user row cannot be updated.
  Future<void> markCurrentCompleted();
}

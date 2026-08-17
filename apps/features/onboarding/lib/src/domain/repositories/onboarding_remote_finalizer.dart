/// Contract for finalizing onboarding on the backend server.
/// Invokes server-side metabolic calculation, master record transfer, and status finalization.
abstract interface class OnboardingRemoteFinalizer {
  /// Executes atomic backend finalization (e.g. POST /api/v1/onboarding/finalize).
  Future<void> finalize();
}

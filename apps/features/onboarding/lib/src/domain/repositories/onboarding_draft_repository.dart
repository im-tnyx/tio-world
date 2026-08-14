import '../models/onboarding_draft_snapshot.dart';

/// Storage-neutral contract for persisting and restoring an unfinished onboarding draft.
///
/// Current production implementation routes directly to Supabase Postgres (RLS-protected).
abstract interface class OnboardingDraftRepository {
  /// Loads the unfinished onboarding draft snapshot for the authenticated user.
  /// Returns null if no draft exists or if the user is unauthenticated.
  Future<OnboardingDraftSnapshot?> loadDraft();

  /// Persists the unfinished onboarding draft [snapshot].
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot);

  /// Clears the obsolete unfinished onboarding draft after successful onboarding completion.
  Future<void> clearDraft();
}

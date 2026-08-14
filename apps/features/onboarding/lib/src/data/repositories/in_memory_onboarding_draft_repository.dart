import '../../domain/models/onboarding_draft_snapshot.dart';
import '../../domain/repositories/onboarding_draft_repository.dart';

/// In-memory implementation of [OnboardingDraftRepository] for testing and offline fallback.
class InMemoryOnboardingDraftRepository implements OnboardingDraftRepository {
  InMemoryOnboardingDraftRepository({OnboardingDraftSnapshot? initialSnapshot})
      : _snapshot = initialSnapshot;

  OnboardingDraftSnapshot? _snapshot;
  bool shouldFailOnSave = false;
  bool shouldFailOnClear = false;

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async => _snapshot;

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) async {
    if (shouldFailOnSave) {
      throw Exception('In-memory save draft failed intentionally');
    }
    _snapshot = snapshot;
  }

  @override
  Future<void> clearDraft() async {
    if (shouldFailOnClear) {
      throw Exception('In-memory clear draft failed intentionally');
    }
    _snapshot = null;
  }
}

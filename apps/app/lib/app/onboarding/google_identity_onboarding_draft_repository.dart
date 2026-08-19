import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

/// Adds a narrow, non-persistent bootstrap draft when a Google-authenticated
/// first-run user has no existing onboarding draft.
///
/// Existing remote/local drafts always win. The synthetic draft only seeds the
/// trusted provider display name and starts the forward Profile flow at Gender;
/// Name remains in [ProfileFlowPlan], so Back from Gender still opens the
/// editable Name screen.
class GoogleIdentityOnboardingDraftRepository
    implements OnboardingDraftRepository {
  GoogleIdentityOnboardingDraftRepository({
    required OnboardingDraftRepository delegate,
    required String? Function() trustedGoogleDisplayName,
    required AppMode? Function() selectedMode,
  })  : _delegate = delegate,
        _trustedGoogleDisplayName = trustedGoogleDisplayName,
        _selectedMode = selectedMode;

  final OnboardingDraftRepository _delegate;
  final String? Function() _trustedGoogleDisplayName;
  final AppMode? Function() _selectedMode;

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    final existing = await _delegate.loadDraft();
    if (existing != null) return existing;

    final mode = _selectedMode();
    final name = _trustedGoogleDisplayName()?.trim();
    if (mode == null || name == null || name.isEmpty) return null;

    return OnboardingDraftSnapshot(
      draft: OnboardingDraft(
        selectedMode: mode,
        currentStepId: OnboardingStepId.profileBasics,
        profile: ProfileOnboardingDraft(
          currentStepId: ProfileStepId.gender,
          name: name,
        ),
      ),
    );
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) {
    return _delegate.saveDraft(snapshot);
  }

  @override
  Future<void> clearDraft() => _delegate.clearDraft();
}

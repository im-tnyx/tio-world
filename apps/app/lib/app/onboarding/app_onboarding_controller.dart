import 'package:tio_feature_onboarding/onboarding.dart';

import 'auth_aware_onboarding_draft_repository.dart';

/// App-owned onboarding controller that records a separate post-auth resume
/// checkpoint without advancing the signed-out screen state.
class AppOnboardingController extends OnboardingController {
  AppOnboardingController({
    required super.entryPath,
    required LocalOnboardingDraftStore localDraftStore,
    super.initialDraft,
    super.includeMobile,
    super.statusRepository,
    super.draftRepository,
    super.completionValidator,
  }) : _localDraftStore = localDraftStore;

  final LocalOnboardingDraftStore _localDraftStore;

  @override
  Future<void> next({
    required Future<void> Function(OnboardingDraft draft) onFinish,
    Future<bool> Function()? onAuthRequired,
  }) {
    final originalOnAuthRequired = onAuthRequired;
    return super.next(
      onFinish: onFinish,
      onAuthRequired: originalOnAuthRequired == null
          ? null
          : () async {
              final currentDraft = state.draft;
              final resumeDraft = _buildResumeAfterAuthDraft();
              final currentRecord = await _localDraftStore.load();

              await _localDraftStore.save(
                LocalOnboardingDraftRecord(
                  draft: OnboardingDraftSnapshot(draft: currentDraft),
                  resumeAfterAuth: OnboardingDraftSnapshot(draft: resumeDraft),
                  boundUserId: currentRecord?.boundUserId,
                ),
              );

              final authenticated = await originalOnAuthRequired();
              if (!authenticated) {
                final record = await _localDraftStore.load();
                if (record != null) {
                  await _localDraftStore.save(
                    record.copyWith(clearResumeAfterAuth: true),
                  );
                }
              }
              return authenticated;
            },
    );
  }

  OnboardingDraft _buildResumeAfterAuthDraft() {
    final currentState = state;
    if (currentState.currentIndex >= currentState.flowPlan.steps.length - 1) {
      return currentState.draft;
    }

    final nextStepId =
        currentState.flowPlan.steps[currentState.currentIndex + 1].id;
    return currentState.draft.copyWith(
      currentStepId: nextStepId,
      completedStepIds: {
        ...currentState.completedStepIds,
        currentState.stepId,
      },
    );
  }
}

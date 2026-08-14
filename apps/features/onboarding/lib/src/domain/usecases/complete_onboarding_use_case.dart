import 'package:tio_shared/shared.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'onboarding_completion_validator.dart';
import 'persist_onboarding_owner_data_use_case.dart';

class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase({
    required AppModePreference confirmedModePreference,
    required OnboardingStatusRepository statusRepository,
    PersistOnboardingOwnerDataUseCase? persistOwnerDataUseCase,
    OnboardingRemoteFinalizer? finalizer,
    OnboardingDraftRepository? draftRepository,
    OnboardingCompletionValidator validator =
        const OnboardingCompletionValidator(),
  })  : _confirmedModePreference = confirmedModePreference,
        _statusRepository = statusRepository,
        _persistOwnerDataUseCase = persistOwnerDataUseCase,
        _finalizer = finalizer,
        _draftRepository = draftRepository,
        _validator = validator;

  final AppModePreference _confirmedModePreference;
  final OnboardingStatusRepository _statusRepository;
  final PersistOnboardingOwnerDataUseCase? _persistOwnerDataUseCase;
  final OnboardingRemoteFinalizer? _finalizer;
  final OnboardingDraftRepository? _draftRepository;
  final OnboardingCompletionValidator _validator;

  Future<void> call({
    required OnboardingDraft draft,
    required OnboardingFlowPlan flowPlan,
  }) async {
    final eligibility = _validator.evaluate(
      draft: draft,
      flowPlan: flowPlan,
    );
    if (!eligibility.isEligible) {
      throw OnboardingCompletionBlockedException(eligibility);
    }

    final selectedMode = draft.selectedMode;
    if (selectedMode == null) {
      throw StateError('Confirmed App Mode requires a selected draft mode.');
    }

    final persistedSnapshot = await _statusRepository.read();
    final persistedMode = await _confirmedModePreference.read();
    if (persistedSnapshot.status == OnboardingStatus.completed &&
        persistedMode != null) {
      return;
    }

    await _statusRepository.ensureInitialized();

    // 1. Persist owner data first (atomic multi-owner transaction)
    if (_persistOwnerDataUseCase != null) {
      await _persistOwnerDataUseCase(
        draft: draft,
        flowPlan: flowPlan,
      );
    }

    // 2. Execute server finalization before local completion publication
    if (_finalizer != null) {
      await _finalizer.finalize();
    }

    // 3. Publish confirmed AppMode
    await _confirmedModePreference.write(selectedMode);

    // 4. Mark Onboarding completed
    await _statusRepository.write(OnboardingStatus.completed);

    // 5. Best-effort clear obsolete unfinished draft (completion is already authoritative)
    if (_draftRepository != null) {
      try {
        await _draftRepository.clearDraft();
      } catch (_) {
        // Safe best-effort: failure to clear draft does not invalidate completed status.
      }
    }
  }
}

class OnboardingCompletionBlockedException implements Exception {
  const OnboardingCompletionBlockedException(this.eligibility);

  final OnboardingCompletionEligibility eligibility;

  @override
  String toString() {
    return eligibility.message ??
        'Onboarding completion is blocked by required setup steps.';
  }
}

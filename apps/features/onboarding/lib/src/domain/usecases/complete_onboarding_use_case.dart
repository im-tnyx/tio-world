import 'package:tio_shared/shared.dart';

import '../models/models.dart';
import '../repositories/repositories.dart';
import 'onboarding_completion_validator.dart';
import 'persist_onboarding_owner_data_use_case.dart';

class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase({
    required AppModePreference confirmedModePreference,
    required OnboardingStatusRepository statusRepository,
    AppPreferencesRepository? appPreferencesRepository,
    PersistOnboardingOwnerDataUseCase? persistOwnerDataUseCase,
    OnboardingRemoteFinalizer? finalizer,
    OnboardingCompletionRepository? completionRepository,
    OnboardingDraftRepository? draftRepository,
    OnboardingCompletionValidator validator =
        const OnboardingCompletionValidator(),
  })  : _confirmedModePreference = confirmedModePreference,
        _statusRepository = statusRepository,
        _appPreferencesRepository = appPreferencesRepository,
        _persistOwnerDataUseCase = persistOwnerDataUseCase,
        _finalizer = finalizer,
        _completionRepository = completionRepository,
        _draftRepository = draftRepository,
        _validator = validator;

  final AppModePreference _confirmedModePreference;
  final OnboardingStatusRepository _statusRepository;
  final AppPreferencesRepository? _appPreferencesRepository;
  final PersistOnboardingOwnerDataUseCase? _persistOwnerDataUseCase;
  final OnboardingRemoteFinalizer? _finalizer;
  final OnboardingCompletionRepository? _completionRepository;
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
        persistedMode == selectedMode &&
        await _hasCanonicalPreferenceFor(selectedMode)) {
      if (_completionRepository == null) {
        return;
      }
      final remoteState = await _completionRepository.readCurrent();
      if (remoteState == RemoteOnboardingCompletionState.completed) {
        return;
      }
    }

    await _statusRepository.ensureInitialized();

    // 1. Persist owner data before publishing any completion signal.
    if (_persistOwnerDataUseCase != null) {
      await _persistOwnerDataUseCase(
        draft: draft,
        flowPlan: flowPlan,
      );
    }

    // 2. Execute optional server-side non-local finalization.
    if (_finalizer != null) {
      await _finalizer.finalize();
    }

    // 3. Persist canonical account-level App Mode/navigation before publishing
    // any local confirmed mode or onboarding completion signal.
    if (_appPreferencesRepository != null) {
      await _appPreferencesRepository.upsert(
        AppPreferencesUpdate.guided(selectedMode),
      );
    }

    // 4. Refresh the local App Mode cache only after canonical persistence.
    await _confirmedModePreference.write(selectedMode);

    // 5. Publish durable backend completion before the local completion cache.
    if (_completionRepository != null) {
      await _completionRepository.markCurrentCompleted();
    }

    // 6. Update the local onboarding completion cache only after backend success.
    await _statusRepository.write(OnboardingStatus.completed);

    // 7. Best-effort clear obsolete unfinished draft.
    if (_draftRepository != null) {
      try {
        await _draftRepository.clearDraft();
      } catch (_) {
        // Safe best-effort: failure to clear draft does not invalidate completion.
      }
    }
  }

  Future<bool> _hasCanonicalPreferenceFor(AppMode selectedMode) async {
    final repository = _appPreferencesRepository;
    if (repository == null) {
      // Compatibility for local/test callers while O1 migrates app composition.
      return true;
    }

    final state = await repository.read();
    final activeTabs = state.activeTabs;
    return state.isPresent &&
        state.appMode == selectedMode &&
        activeTabs != null &&
        activeTabs.isNotEmpty;
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

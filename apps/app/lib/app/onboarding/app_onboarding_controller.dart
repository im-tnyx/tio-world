import 'dart:async';

import 'package:tio_feature_onboarding/onboarding.dart';

import 'auth_aware_onboarding_draft_repository.dart';

/// App-owned onboarding controller that records a separate post-auth resume
/// checkpoint without advancing the signed-out screen state.
///
/// This must remain Nutrition-aware because the production app overrides the
/// feature controller provider with this app-owned controller. Extending the
/// plain [OnboardingController] would bypass Nutrition Profile child-step
/// selection and navigation in the real app composition.
class AppOnboardingController extends NutritionAwareOnboardingController {
  AppOnboardingController({
    required OnboardingEntryPath entryPath,
    required LocalOnboardingDraftStore localDraftStore,
    OnboardingDraft? initialDraft,
    bool includeMobile = false,
    OnboardingStatusRepository statusRepository =
        const NoOpOnboardingStatusRepository(),
    OnboardingDraftRepository? draftRepository,
    OnboardingCompletionValidator completionValidator =
        const OnboardingCompletionValidator(),
  })  : _localDraftStore = localDraftStore,
        super(
          entryPath: entryPath,
          initialDraft: initialDraft,
          includeMobile: includeMobile,
          statusRepository:
              _DeduplicatingOnboardingStatusRepository(statusRepository),
          draftRepository: draftRepository == null
              ? null
              : _SerializingOnboardingDraftRepository(draftRepository),
          completionValidator: completionValidator,
        );

  final LocalOnboardingDraftStore _localDraftStore;
  bool _isDisposed = false;

  @override
  Future<void> hydrateDraft() async {
    await super.hydrateDraft();
    if (!_isDisposed) {
      // The base controller marks hydration complete after applying the loaded
      // draft. Publish that readiness so the UI can render only the resolved
      // onboarding step instead of briefly showing the default App Mode step.
      notifyListeners();
    }
  }

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

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

/// Collapses repeated writes of the same persisted onboarding status while
/// still allowing a later edit to retry after a failed read or write.
class _DeduplicatingOnboardingStatusRepository
    implements OnboardingStatusRepository {
  _DeduplicatingOnboardingStatusRepository(this._delegate);

  final OnboardingStatusRepository _delegate;
  bool _hasObservedPersistedStatus = false;
  OnboardingStatus? _lastSuccessfulWrite;
  OnboardingStatus? _inFlightStatus;
  Future<void>? _inFlightWrite;

  @override
  Future<void> clear() async {
    await _delegate.clear();
    _hasObservedPersistedStatus = false;
    _lastSuccessfulWrite = null;
  }

  @override
  Future<void> ensureInitialized() => _delegate.ensureInitialized();

  @override
  Future<OnboardingStatusSnapshot> read() async {
    final snapshot = await _delegate.read();
    _hasObservedPersistedStatus = true;
    _lastSuccessfulWrite = snapshot.status;
    return snapshot;
  }

  @override
  Future<void> write(OnboardingStatus status) {
    if (_hasObservedPersistedStatus && _lastSuccessfulWrite == status) {
      return Future<void>.value();
    }

    final inFlightWrite = _inFlightWrite;
    if (inFlightWrite != null && _inFlightStatus == status) {
      return inFlightWrite;
    }

    late final Future<void> operation;
    operation = _writeIfChanged(status).whenComplete(() {
      if (identical(_inFlightWrite, operation)) {
        _inFlightStatus = null;
        _inFlightWrite = null;
      }
    });
    _inFlightStatus = status;
    _inFlightWrite = operation;
    return operation;
  }

  Future<void> _writeIfChanged(OnboardingStatus status) async {
    if (!_hasObservedPersistedStatus) {
      final snapshot = await _delegate.read();
      _hasObservedPersistedStatus = true;
      _lastSuccessfulWrite = snapshot.status;
    }
    if (_lastSuccessfulWrite == status) return;

    await _delegate.write(status);
    _lastSuccessfulWrite = status;
  }
}

/// Orders app-generated draft mutations so an older network request cannot
/// finish after and overwrite a newer onboarding snapshot.
class _SerializingOnboardingDraftRepository
    implements OnboardingDraftRepository {
  _SerializingOnboardingDraftRepository(this._delegate);

  final OnboardingDraftRepository _delegate;
  Future<void> _tail = Future<void>.value();

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    await _tail;
    return _delegate.loadDraft();
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) {
    return _enqueue(() => _delegate.saveDraft(snapshot));
  }

  @override
  Future<void> clearDraft() {
    return _enqueue(_delegate.clearDraft);
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    final result = Completer<void>();
    _tail = _tail.then((_) async {
      try {
        await operation();
        result.complete();
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });
    return result.future;
  }
}

import 'dart:async';

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
    OnboardingStatusRepository statusRepository =
        const NoOpOnboardingStatusRepository(),
    OnboardingDraftRepository? draftRepository,
    super.completionValidator,
  })  : _localDraftStore = localDraftStore,
        super(
          statusRepository:
              _DeduplicatingOnboardingStatusRepository(statusRepository),
          draftRepository: draftRepository == null
              ? null
              : _SerializingOnboardingDraftRepository(draftRepository),
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

/// Collapses repeated writes of the same successfully persisted onboarding
/// status while still allowing a later edit to retry after a failed write.
class _DeduplicatingOnboardingStatusRepository
    implements OnboardingStatusRepository {
  _DeduplicatingOnboardingStatusRepository(this._delegate);

  final OnboardingStatusRepository _delegate;
  OnboardingStatus? _lastSuccessfulWrite;
  OnboardingStatus? _inFlightStatus;
  Future<void>? _inFlightWrite;

  @override
  Future<void> clear() async {
    await _delegate.clear();
    _lastSuccessfulWrite = null;
  }

  @override
  Future<void> ensureInitialized() => _delegate.ensureInitialized();

  @override
  Future<OnboardingStatusSnapshot> read() async {
    final snapshot = await _delegate.read();
    _lastSuccessfulWrite = snapshot.status;
    return snapshot;
  }

  @override
  Future<void> write(OnboardingStatus status) {
    if (_lastSuccessfulWrite == status) {
      return Future<void>.value();
    }

    final inFlightWrite = _inFlightWrite;
    if (inFlightWrite != null && _inFlightStatus == status) {
      return inFlightWrite;
    }

    late final Future<void> operation;
    operation = _delegate.write(status).then((_) {
      _lastSuccessfulWrite = status;
    }).whenComplete(() {
      if (identical(_inFlightWrite, operation)) {
        _inFlightStatus = null;
        _inFlightWrite = null;
      }
    });
    _inFlightStatus = status;
    _inFlightWrite = operation;
    return operation;
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

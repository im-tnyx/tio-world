import 'dart:async';

import '../../domain/domain.dart';

/// Persists the furthest still-valid onboarding cursor while allowing the
/// controller to navigate backward freely in memory.
///
/// The latest successfully loaded/saved snapshot is the durable resume
/// baseline. Incoming saves may contain an earlier visible cursor after Back;
/// [PreserveOnboardingResumeCheckpointUseCase] merges the latest field values
/// with the furthest valid cursor before delegating persistence.
class ResumePreservingOnboardingDraftRepository
    implements OnboardingDraftRepository {
  ResumePreservingOnboardingDraftRepository({
    required OnboardingDraftRepository delegate,
    this.entryPath = OnboardingEntryPath.resumeDraft,
    PreserveOnboardingResumeCheckpointUseCase resolver =
        const PreserveOnboardingResumeCheckpointUseCase(),
  })  : _delegate = delegate,
        _resolver = resolver;

  final OnboardingDraftRepository _delegate;
  final OnboardingEntryPath entryPath;
  final PreserveOnboardingResumeCheckpointUseCase _resolver;

  OnboardingDraftSnapshot? _resumeBaseline;
  Future<void> _saveQueue = Future<void>.value();

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    await _saveQueue;
    final snapshot = await _delegate.loadDraft();
    _resumeBaseline = snapshot;
    return snapshot;
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) {
    final completer = Completer<void>();

    _saveQueue = _saveQueue.then((_) async {
      try {
        final persistedDraft = _resolver(
          entryPath: entryPath,
          visibleDraft: snapshot.draft,
          previousPersistedDraft: _resumeBaseline?.draft,
        );
        final persistedSnapshot = OnboardingDraftSnapshot(
          schemaVersion: snapshot.schemaVersion,
          draft: persistedDraft,
          updatedAt: snapshot.updatedAt,
        );

        await _delegate.saveDraft(persistedSnapshot);
        _resumeBaseline = persistedSnapshot;
        completer.complete();
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });

    return completer.future;
  }

  @override
  Future<void> clearDraft() async {
    await _saveQueue;
    await _delegate.clearDraft();
    _resumeBaseline = null;
  }
}

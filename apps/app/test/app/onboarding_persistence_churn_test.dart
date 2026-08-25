import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('AppOnboardingController persistence hardening', () {
    test('repeated edits persist in-progress status once after success', () async {
      final statusRepository = _RecordingStatusRepository();
      final controller = AppOnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        localDraftStore: _MemoryLocalDraftStore(),
        statusRepository: statusRepository,
      );

      controller.updateProfileName('A');
      controller.updateProfileName('AB');
      await _drainAsyncWork();

      expect(
        statusRepository.writes,
        [OnboardingStatus.inProgress],
      );

      controller.updateProfileName('ABC');
      await _drainAsyncWork();

      expect(
        statusRepository.writes,
        [OnboardingStatus.inProgress],
      );
      controller.dispose();
    });

    test('failed in-progress status write retries on a later edit', () async {
      final statusRepository = _RecordingStatusRepository(failNextWrite: true);
      final controller = AppOnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        localDraftStore: _MemoryLocalDraftStore(),
        statusRepository: statusRepository,
      );

      controller.updateProfileName('First');
      await _drainAsyncWork();
      expect(statusRepository.writes.length, 1);

      controller.updateProfileName('Second');
      await _drainAsyncWork();

      expect(
        statusRepository.writes,
        [
          OnboardingStatus.inProgress,
          OnboardingStatus.inProgress,
        ],
      );
      controller.dispose();
    });

    test('immediate draft saves are serialized and preserve mutation order',
        () async {
      final draftRepository = _BlockingDraftRepository();
      final controller = AppOnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        localDraftStore: _MemoryLocalDraftStore(),
        draftRepository: draftRepository,
      );
      await controller.hydrateDraft();

      controller.selectMode(AppMode.nutrition);
      await _drainAsyncWork();

      expect(draftRepository.started.length, 1);
      expect(
        draftRepository.started.single.draft.selectedMode,
        AppMode.nutrition,
      );

      controller.selectMode(AppMode.workout);
      await _drainAsyncWork();

      // The second immediate save is queued behind the first rather than
      // overlapping it and becoming vulnerable to stale completion order.
      expect(draftRepository.started.length, 1);

      draftRepository.complete(0);
      await _drainAsyncWork();

      expect(draftRepository.started.length, 2);
      expect(
        draftRepository.started[1].draft.selectedMode,
        AppMode.workout,
      );

      draftRepository.complete(1);
      await _drainAsyncWork();
      controller.dispose();
    });
  });
}

Future<void> _drainAsyncWork() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}

class _RecordingStatusRepository implements OnboardingStatusRepository {
  _RecordingStatusRepository({this.failNextWrite = false});

  bool failNextWrite;
  final List<OnboardingStatus> writes = [];

  @override
  Future<void> clear() async {}

  @override
  Future<void> ensureInitialized() async {}

  @override
  Future<OnboardingStatusSnapshot> read() async {
    return const OnboardingStatusSnapshot(
      status: null,
      hasStoredContractVersion: false,
    );
  }

  @override
  Future<void> write(OnboardingStatus status) async {
    writes.add(status);
    if (failNextWrite) {
      failNextWrite = false;
      throw StateError('status write failed');
    }
  }
}

class _BlockingDraftRepository implements OnboardingDraftRepository {
  final List<OnboardingDraftSnapshot> started = [];
  final List<Completer<void>> _pending = [];

  @override
  Future<void> clearDraft() async {}

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async => null;

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) {
    started.add(snapshot);
    final completer = Completer<void>();
    _pending.add(completer);
    return completer.future;
  }

  void complete(int index) {
    _pending[index].complete();
  }
}

class _MemoryLocalDraftStore implements LocalOnboardingDraftStore {
  LocalOnboardingDraftRecord? record;

  @override
  Future<void> clear() async {
    record = null;
  }

  @override
  Future<LocalOnboardingDraftRecord?> load() async => record;

  @override
  Future<void> save(LocalOnboardingDraftRecord record) async {
    this.record = record;
  }
}

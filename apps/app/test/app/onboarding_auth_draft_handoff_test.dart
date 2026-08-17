import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

import 'package:tio_app/app/onboarding/onboarding.dart';

void main() {
  group('AuthAwareOnboardingDraftRepository', () {
    test('signed-out saves stay local and never call the remote repository',
        () async {
      String? userId;
      final local = _MemoryLocalDraftStore();
      final remote = _RecordingRemoteDraftRepository();
      final repository = AuthAwareOnboardingDraftRepository(
        localStore: local,
        currentUserId: () => userId,
        remoteRepository: remote,
      );
      final snapshot = OnboardingDraftSnapshot(
        draft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          currentStepId: OnboardingStepId.profileBasics,
          profile: _validProfile(),
        ),
      );

      await repository.saveDraft(snapshot);

      expect(local.record?.draft.draft.selectedMode, AppMode.nutrition);
      expect(local.record?.draft.draft.profile.heightCm, 171);
      expect(local.record?.draft.draft.profile.currentWeightKg, 70);
      expect(remote.saveCalls, 0);
      repository.dispose();
    });

    test('fresh authenticated user migrates the post-auth resume draft once',
        () async {
      const userId = 'fresh-user';
      final currentDraft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.profileBasics,
        completedStepIds: const {OnboardingStepId.mode},
        profile: _validProfile(),
      );
      final resumeDraft = currentDraft.copyWith(
        currentStepId: OnboardingStepId.targets,
        completedStepIds: const {
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
        },
      );
      final local = _MemoryLocalDraftStore(
        LocalOnboardingDraftRecord(
          draft: OnboardingDraftSnapshot(draft: currentDraft),
          resumeAfterAuth: OnboardingDraftSnapshot(draft: resumeDraft),
        ),
      );
      final remote = _RecordingRemoteDraftRepository();
      final repository = AuthAwareOnboardingDraftRepository(
        localStore: local,
        currentUserId: () => userId,
        remoteRepository: remote,
      );

      final loaded = await repository.loadDraft();

      expect(loaded?.draft.currentStepId, OnboardingStepId.targets);
      expect(loaded?.draft.profile.name, 'Tio User');
      expect(loaded?.draft.profile.heightCm, 171);
      expect(loaded?.draft.profile.currentWeightKg, 70);
      expect(remote.saveCalls, 1);
      expect(remote.saved?.draft.currentStepId, OnboardingStepId.targets);
      expect(local.record, isNull);
      repository.dispose();
    });

    test('existing remote user draft stays authoritative over local pre-auth data',
        () async {
      const userId = 'existing-user';
      final local = _MemoryLocalDraftStore(
        LocalOnboardingDraftRecord(
          draft: OnboardingDraftSnapshot(
            draft: OnboardingDraft(
              selectedMode: AppMode.workout,
              currentStepId: OnboardingStepId.profileBasics,
              profile: _validProfile(),
            ),
          ),
          resumeAfterAuth: OnboardingDraftSnapshot(
            draft: OnboardingDraft(
              selectedMode: AppMode.workout,
              currentStepId: OnboardingStepId.workoutPreferences,
              profile: _validProfile(),
            ),
          ),
        ),
      );
      final remoteDraft = OnboardingDraft(
        selectedMode: AppMode.nutrition,
        currentStepId: OnboardingStepId.review,
        completedStepIds: const {
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
          OnboardingStepId.targets,
        },
        profile: _validProfile(),
      );
      final remote = _RecordingRemoteDraftRepository(remoteDraft: remoteDraft);
      final repository = AuthAwareOnboardingDraftRepository(
        localStore: local,
        currentUserId: () => userId,
        remoteRepository: remote,
      );

      final loaded = await repository.loadDraft();

      expect(loaded?.draft.currentStepId, OnboardingStepId.review);
      expect(loaded?.draft.selectedMode, AppMode.nutrition);
      expect(remote.saveCalls, 0);
      expect(local.record, isNull);
      repository.dispose();
    });

    test('a local draft bound to another identity is discarded, not migrated',
        () async {
      final local = _MemoryLocalDraftStore(
        LocalOnboardingDraftRecord(
          draft: OnboardingDraftSnapshot(
            draft: OnboardingDraft(
              selectedMode: AppMode.hybrid,
              profile: _validProfile(),
            ),
          ),
          boundUserId: 'user-a',
        ),
      );
      final remote = _RecordingRemoteDraftRepository();
      final repository = AuthAwareOnboardingDraftRepository(
        localStore: local,
        currentUserId: () => 'user-b',
        remoteRepository: remote,
      );

      expect(await repository.loadDraft(), isNull);
      expect(remote.saveCalls, 0);
      expect(local.record, isNull);
      repository.dispose();
    });

    test('auth lifecycle binds a staged draft then clears it after sign-out',
        () async {
      String? userId;
      final userIds = StreamController<String?>();
      final local = _MemoryLocalDraftStore(
        LocalOnboardingDraftRecord(
          draft: OnboardingDraftSnapshot(
            draft: OnboardingDraft(
              selectedMode: AppMode.workout,
              profile: _validProfile(),
            ),
          ),
        ),
      );
      final repository = AuthAwareOnboardingDraftRepository(
        localStore: local,
        currentUserId: () => userId,
        userIdChanges: userIds.stream,
      );

      userId = 'user-a';
      userIds.add(userId);
      await Future<void>.delayed(Duration.zero);
      expect(local.record?.boundUserId, 'user-a');

      userId = null;
      userIds.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(local.record, isNull);

      await userIds.close();
      repository.dispose();
    });
  });

  group('AppOnboardingController auth checkpoint', () {
    test('keeps signed-out screen draft and stages exact post-auth resume data',
        () async {
      final local = _MemoryLocalDraftStore();
      final authResult = Completer<bool>();
      final controller = AppOnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          currentStepId: OnboardingStepId.profileBasics,
          completedStepIds: const {OnboardingStepId.mode},
          profile: _validProfile(),
        ),
        localDraftStore: local,
      );

      final nextFuture = controller.next(
        onFinish: (_) async {},
        onAuthRequired: () => authResult.future,
      );
      await Future<void>.delayed(Duration.zero);

      final record = local.record;
      expect(record, isNotNull);
      expect(record!.draft.draft.currentStepId, OnboardingStepId.profileBasics);
      expect(record.draft.draft.profile.name, 'Tio User');
      expect(record.draft.draft.profile.heightCm, 171);
      expect(record.draft.draft.profile.currentWeightKg, 70);
      expect(record.resumeAfterAuth?.draft.currentStepId, OnboardingStepId.targets);
      expect(
        record.resumeAfterAuth?.draft.completedStepIds,
        containsAll(const {
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
        }),
      );
      expect(controller.state.stepId, OnboardingStepId.profileBasics);

      authResult.complete(false);
      await nextFuture;

      expect(local.record?.resumeAfterAuth, isNull);
      expect(local.record?.draft.draft.currentStepId,
          OnboardingStepId.profileBasics);
      controller.dispose();
    });

    test('publishes hydrated resolved step for the render gate', () async {
      final remoteDraft = OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.workoutPreferences,
        completedStepIds: const {
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
        },
        profile: _validProfile(),
      );
      final controller = AppOnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        localDraftStore: _MemoryLocalDraftStore(),
        draftRepository:
            _RecordingRemoteDraftRepository(remoteDraft: remoteDraft),
      );
      var hydratedNotificationSeen = false;
      controller.addListener(() {
        if (controller.isHydrated) hydratedNotificationSeen = true;
      });

      expect(controller.isHydrated, isFalse);
      expect(controller.state.stepId, OnboardingStepId.mode);

      await controller.hydrateDraft();

      expect(controller.isHydrated, isTrue);
      expect(controller.state.stepId, OnboardingStepId.workoutPreferences);
      expect(hydratedNotificationSeen, isTrue);
      controller.dispose();
    });
  });
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    currentStepId: ProfileStepId.healthConditions,
    name: 'Tio User',
    gender: ProfileGender.other,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 70,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

class _MemoryLocalDraftStore implements LocalOnboardingDraftStore {
  _MemoryLocalDraftStore([this.record]);

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

class _RecordingRemoteDraftRepository implements OnboardingDraftRepository {
  _RecordingRemoteDraftRepository({this.remoteDraft});

  final OnboardingDraft? remoteDraft;
  int saveCalls = 0;
  OnboardingDraftSnapshot? saved;

  @override
  Future<void> clearDraft() async {}

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    final draft = remoteDraft;
    return draft == null ? null : OnboardingDraftSnapshot(draft: draft);
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) async {
    saveCalls++;
    saved = snapshot;
  }
}

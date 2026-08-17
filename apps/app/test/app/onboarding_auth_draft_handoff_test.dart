import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

import 'package:tio_app/app/onboarding/onboarding.dart';

void main() {
  group('OnboardingAuthDraftHandoff', () {
    test('does not consume while unauthenticated and rejects another identity',
        () {
      final handoff = OnboardingAuthDraftHandoff();
      final draft = OnboardingDraft(selectedMode: AppMode.nutrition);

      handoff.stage(draft);

      expect(handoff.takeForUser(null), isNull);
      expect(handoff.hasPendingDraft, isTrue);

      handoff.bindAuthenticatedUser('user-a');
      expect(handoff.takeForUser('user-b'), isNull);
      expect(handoff.hasPendingDraft, isFalse);

      handoff.dispose();
    });

    test('matching authenticated identity consumes staged draft once', () {
      final handoff = OnboardingAuthDraftHandoff();
      final draft = OnboardingDraft(selectedMode: AppMode.workout);

      handoff.stage(draft);
      handoff.bindAuthenticatedUser('user-a');

      expect(handoff.takeForUser('user-a'), same(draft));
      expect(handoff.takeForUser('user-a'), isNull);
      expect(handoff.hasPendingDraft, isFalse);

      handoff.dispose();
    });
  });

  group('AppOnboardingController auth checkpoint', () {
    test('stages the first post-profile step before auth result returns',
        () async {
      final handoff = OnboardingAuthDraftHandoff();
      final authResult = Completer<bool>();
      final controller = AppOnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          currentStepId: OnboardingStepId.profileBasics,
          completedStepIds: const {OnboardingStepId.mode},
          profile: _validProfile(),
        ),
        authDraftHandoff: handoff,
      );

      final nextFuture = controller.next(
        onFinish: (_) async {},
        onAuthRequired: () => authResult.future,
      );
      await Future<void>.delayed(Duration.zero);

      final resumeDraft = handoff.takeForUser('fresh-user');
      expect(resumeDraft, isNotNull);
      expect(resumeDraft!.selectedMode, AppMode.nutrition);
      expect(resumeDraft.currentStepId, OnboardingStepId.targets);
      expect(
        resumeDraft.completedStepIds,
        containsAll(const {
          OnboardingStepId.mode,
          OnboardingStepId.profileBasics,
        }),
      );
      expect(controller.state.stepId, OnboardingStepId.profileBasics);

      authResult.complete(false);
      await nextFuture;

      controller.dispose();
      handoff.dispose();
    });

    test('cancelled authentication clears an unconsumed staged draft', () async {
      final handoff = OnboardingAuthDraftHandoff();
      final controller = AppOnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          currentStepId: OnboardingStepId.profileBasics,
          completedStepIds: const {OnboardingStepId.mode},
          profile: _validProfile(),
        ),
        authDraftHandoff: handoff,
      );

      await controller.next(
        onFinish: (_) async {},
        onAuthRequired: () async => false,
      );

      expect(handoff.hasPendingDraft, isFalse);
      expect(controller.state.stepId, OnboardingStepId.profileBasics);

      controller.dispose();
      handoff.dispose();
    });

    test('remote user-owned draft remains authoritative over handoff seed',
        () async {
      final handoff = OnboardingAuthDraftHandoff();
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
      final controller = AppOnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          currentStepId: OnboardingStepId.targets,
          completedStepIds: const {
            OnboardingStepId.mode,
            OnboardingStepId.profileBasics,
          },
          profile: _validProfile(),
        ),
        draftRepository: _RemoteDraftRepository(remoteDraft),
        authDraftHandoff: handoff,
      );

      await controller.hydrateDraft();

      expect(controller.state.stepId, OnboardingStepId.review);
      expect(controller.state.draft.currentStepId, OnboardingStepId.review);

      controller.dispose();
      handoff.dispose();
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

class _RemoteDraftRepository implements OnboardingDraftRepository {
  _RemoteDraftRepository(this.draft);

  final OnboardingDraft draft;

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async {
    return OnboardingDraftSnapshot(draft: draft);
  }

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) async {}

  @override
  Future<void> clearDraft() async {}
}

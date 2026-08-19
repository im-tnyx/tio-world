import 'package:flutter_test/flutter_test.dart';
import 'package:tio_app/app/onboarding/onboarding.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('GoogleIdentityOnboardingDraftRepository', () {
    test('existing draft stays authoritative over Google bootstrap', () async {
      final existing = OnboardingDraftSnapshot(
        draft: OnboardingDraft(
          selectedMode: AppMode.workout,
          currentStepId: OnboardingStepId.profileBasics,
          profile: ProfileOnboardingDraft(
            currentStepId: ProfileStepId.goal,
            name: 'Edited Name',
            gender: ProfileGender.other,
          ),
        ),
      );
      final repository = GoogleIdentityOnboardingDraftRepository(
        delegate: _MemoryDraftRepository(existing),
        trustedGoogleDisplayName: () => 'Google Name',
        selectedMode: () => AppMode.nutrition,
      );

      final loaded = await repository.loadDraft();

      expect(loaded, same(existing));
      expect(loaded?.draft.profile.name, 'Edited Name');
      expect(loaded?.draft.profile.currentStepId, ProfileStepId.goal);
      expect(loaded?.draft.selectedMode, AppMode.workout);
    });

    test('Google name seeds Profile at Gender while keeping Name editable',
        () async {
      final repository = GoogleIdentityOnboardingDraftRepository(
        delegate: _MemoryDraftRepository(),
        trustedGoogleDisplayName: () => '  Google User  ',
        selectedMode: () => AppMode.hybrid,
      );

      final loaded = await repository.loadDraft();

      expect(loaded?.draft.selectedMode, AppMode.hybrid);
      expect(loaded?.draft.currentStepId, OnboardingStepId.profileBasics);
      expect(loaded?.draft.profile.name, 'Google User');
      expect(loaded?.draft.profile.currentStepId, ProfileStepId.gender);

      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: loaded!.draft,
      );
      controller.previous();

      expect(controller.state.stepId, OnboardingStepId.profileBasics);
      expect(controller.state.draft.profile.currentStepId, ProfileStepId.name);
      expect(controller.state.draft.profile.name, 'Google User');
      controller.dispose();
    });

    test('missing usable Google name falls back to normal Name entry', () async {
      final repository = GoogleIdentityOnboardingDraftRepository(
        delegate: _MemoryDraftRepository(),
        trustedGoogleDisplayName: () => '   ',
        selectedMode: () => AppMode.workout,
      );

      expect(await repository.loadDraft(), isNull);
    });

    test('missing selected App Mode does not create a synthetic draft',
        () async {
      final repository = GoogleIdentityOnboardingDraftRepository(
        delegate: _MemoryDraftRepository(),
        trustedGoogleDisplayName: () => 'Google User',
        selectedMode: () => null,
      );

      expect(await repository.loadDraft(), isNull);
    });

    test('save and clear remain delegated', () async {
      final delegate = _MemoryDraftRepository();
      final repository = GoogleIdentityOnboardingDraftRepository(
        delegate: delegate,
        trustedGoogleDisplayName: () => 'Google User',
        selectedMode: () => AppMode.workout,
      );
      final snapshot = OnboardingDraftSnapshot(
        draft: OnboardingDraft(selectedMode: AppMode.workout),
      );

      await repository.saveDraft(snapshot);
      expect(delegate.snapshot, same(snapshot));

      await repository.clearDraft();
      expect(delegate.snapshot, isNull);
    });
  });
}

class _MemoryDraftRepository implements OnboardingDraftRepository {
  _MemoryDraftRepository([this.snapshot]);

  OnboardingDraftSnapshot? snapshot;

  @override
  Future<OnboardingDraftSnapshot?> loadDraft() async => snapshot;

  @override
  Future<void> saveDraft(OnboardingDraftSnapshot snapshot) async {
    this.snapshot = snapshot;
  }

  @override
  Future<void> clearDraft() async {
    snapshot = null;
  }
}

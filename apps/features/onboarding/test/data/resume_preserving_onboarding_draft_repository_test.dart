import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('Back save keeps Activity as the durable resume cursor', () async {
    final activityDraft = OnboardingDraft(
      selectedMode: AppMode.workout,
      currentStepId: OnboardingStepId.profileBasics,
      profile: _validProfile(currentStepId: ProfileStepId.activity),
    );
    final delegate = InMemoryOnboardingDraftRepository(
      initialSnapshot: OnboardingDraftSnapshot(draft: activityDraft),
    );
    final repository = ResumePreservingOnboardingDraftRepository(
      delegate: delegate,
    );

    final loaded = await repository.loadDraft();
    expect(loaded?.draft.profile.currentStepId, ProfileStepId.activity);

    final visibleName = activityDraft.copyWith(
      profile: activityDraft.profile.copyWith(
        currentStepId: ProfileStepId.name,
        name: 'Edited User',
      ),
    );
    await repository.saveDraft(OnboardingDraftSnapshot(draft: visibleName));

    final persisted = await delegate.loadDraft();
    expect(persisted?.draft.profile.currentStepId, ProfileStepId.activity);
    expect(persisted?.draft.profile.name, 'Edited User');

    final nextSessionRepository = ResumePreservingOnboardingDraftRepository(
      delegate: delegate,
    );
    final resumed = await nextSessionRepository.loadDraft();
    expect(resumed?.draft.profile.currentStepId, ProfileStepId.activity);
  });

  test('queued Back saves cannot overwrite a later durable cursor', () async {
    final delegate = InMemoryOnboardingDraftRepository();
    final repository = ResumePreservingOnboardingDraftRepository(
      delegate: delegate,
    );
    await repository.loadDraft();

    final activityDraft = OnboardingDraft(
      selectedMode: AppMode.workout,
      currentStepId: OnboardingStepId.profileBasics,
      profile: _validProfile(currentStepId: ProfileStepId.activity),
    );
    await repository.saveDraft(OnboardingDraftSnapshot(draft: activityDraft));

    final genderDraft = activityDraft.copyWith(
      profile: activityDraft.profile.copyWith(currentStepId: ProfileStepId.gender),
    );
    final nameDraft = activityDraft.copyWith(
      profile: activityDraft.profile.copyWith(currentStepId: ProfileStepId.name),
    );

    await Future.wait([
      repository.saveDraft(OnboardingDraftSnapshot(draft: genderDraft)),
      repository.saveDraft(OnboardingDraftSnapshot(draft: nameDraft)),
    ]);

    final persisted = await delegate.loadDraft();
    expect(persisted?.draft.profile.currentStepId, ProfileStepId.activity);
  });
}

ProfileOnboardingDraft _validProfile({required ProfileStepId currentStepId}) {
  return ProfileOnboardingDraft(
    currentStepId: currentStepId,
    name: 'Tio User',
    gender: ProfileGender.other,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 68,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

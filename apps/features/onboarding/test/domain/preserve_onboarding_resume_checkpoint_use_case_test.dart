import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const resolver = PreserveOnboardingResumeCheckpointUseCase();

  test('Back to Name does not rewind an Activity resume checkpoint', () {
    final previous = OnboardingDraft(
      selectedMode: AppMode.workout,
      currentStepId: OnboardingStepId.profileBasics,
      profile: _validProfile(currentStepId: ProfileStepId.activity),
    );
    final visibleAfterBack = previous.copyWith(
      profile: previous.profile.copyWith(
        currentStepId: ProfileStepId.name,
        name: 'Updated User',
      ),
    );

    final persisted = resolver(
      entryPath: OnboardingEntryPath.resumeDraft,
      visibleDraft: visibleAfterBack,
      previousPersistedDraft: previous,
    );

    expect(persisted.currentStepId, OnboardingStepId.profileBasics);
    expect(persisted.profile.currentStepId, ProfileStepId.activity);
    expect(persisted.profile.name, 'Updated User');
  });

  test('invalid earlier Profile edit clamps resume checkpoint to that step', () {
    final previous = OnboardingDraft(
      selectedMode: AppMode.workout,
      currentStepId: OnboardingStepId.profileBasics,
      profile: _validProfile(currentStepId: ProfileStepId.activity),
    );
    final visibleAfterInvalidEdit = previous.copyWith(
      profile: previous.profile.copyWith(
        currentStepId: ProfileStepId.name,
        name: '',
      ),
    );

    final persisted = resolver(
      entryPath: OnboardingEntryPath.resumeDraft,
      visibleDraft: visibleAfterInvalidEdit,
      previousPersistedDraft: previous,
    );

    expect(persisted.currentStepId, OnboardingStepId.profileBasics);
    expect(persisted.profile.currentStepId, ProfileStepId.name);
    expect(persisted.completedStepIds, isEmpty);
  });

  test('forward Profile progress advances beyond the previous checkpoint', () {
    final previous = OnboardingDraft(
      selectedMode: AppMode.workout,
      currentStepId: OnboardingStepId.profileBasics,
      profile: _validProfile(currentStepId: ProfileStepId.activity),
    );
    final visibleForward = previous.copyWith(
      profile: previous.profile.copyWith(
        currentStepId: ProfileStepId.healthConditions,
      ),
    );

    final persisted = resolver(
      entryPath: OnboardingEntryPath.resumeDraft,
      visibleDraft: visibleForward,
      previousPersistedDraft: previous,
    );

    expect(persisted.profile.currentStepId, ProfileStepId.healthConditions);
  });

  test('Back inside Body Goal keeps the furthest valid Body Goal child', () {
    final previous = OnboardingDraft(
      selectedMode: AppMode.workout,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
      currentStepId: OnboardingStepId.bodyGoal,
      completedStepIds: const {OnboardingStepId.profileBasics},
      profile: _validProfile(currentStepId: ProfileStepId.targetWeight),
    );
    final visibleAfterBack = previous.copyWith(
      profile: previous.profile.copyWith(currentStepId: ProfileStepId.goal),
    );

    final persisted = resolver(
      entryPath: OnboardingEntryPath.resumeDraft,
      visibleDraft: visibleAfterBack,
      previousPersistedDraft: previous,
    );

    expect(persisted.currentStepId, OnboardingStepId.bodyGoal);
    expect(persisted.profile.currentStepId, ProfileStepId.targetWeight);
    expect(
      persisted.completedStepIds,
      contains(OnboardingStepId.profileBasics),
    );
  });

  test('invalid earlier Body Goal edit clamps durable cursor to that child', () {
    final previous = OnboardingDraft(
      selectedMode: AppMode.workout,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
      currentStepId: OnboardingStepId.bodyGoal,
      completedStepIds: const {OnboardingStepId.profileBasics},
      profile: _validProfile(currentStepId: ProfileStepId.targetWeight),
    );
    final visibleAfterInvalidEdit = previous.copyWith(
      profile: previous.profile.copyWith(
        currentStepId: ProfileStepId.currentWeight,
        currentWeightKg: 10,
      ),
    );

    final persisted = resolver(
      entryPath: OnboardingEntryPath.resumeDraft,
      visibleDraft: visibleAfterInvalidEdit,
      previousPersistedDraft: previous,
    );

    expect(persisted.currentStepId, OnboardingStepId.bodyGoal);
    expect(persisted.profile.currentStepId, ProfileStepId.currentWeight);
    expect(persisted.profile.currentWeightKg, 10);
    expect(
      persisted.completedStepIds,
      contains(OnboardingStepId.profileBasics),
    );
    expect(
      persisted.completedStepIds,
      isNot(contains(OnboardingStepId.bodyGoal)),
    );
  });

  test('legacy profileBasics Body cursor migrates to canonical bodyGoal cursor', () {
    final previousLegacy = OnboardingDraft(
      selectedMode: AppMode.workout,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
      ),
      currentStepId: OnboardingStepId.profileBasics,
      completedStepIds: const {},
      profile: _validProfile(currentStepId: ProfileStepId.targetWeight),
    );
    final visible = previousLegacy.copyWith(
      currentStepId: OnboardingStepId.bodyGoal,
      profile: previousLegacy.profile.copyWith(currentStepId: ProfileStepId.goal),
    );

    final persisted = resolver(
      entryPath: OnboardingEntryPath.resumeDraft,
      visibleDraft: visible,
      previousPersistedDraft: previousLegacy,
    );

    expect(persisted.currentStepId, OnboardingStepId.bodyGoal);
    expect(persisted.profile.currentStepId, ProfileStepId.targetWeight);
    expect(persisted.profile.currentWeightKg, 70);
    expect(persisted.profile.targetWeightKg, 68);
  });

  test('later section resume survives Back into Profile when prior data is valid',
      () {
    final previous = OnboardingDraft(
      selectedMode: AppMode.workout,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.stayFit,
      ),
      currentStepId: OnboardingStepId.targets,
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: const TargetsOnboardingDraft(
        currentStepId: TargetStepId.waterTarget,
      ),
      completedStepIds: const {
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.workoutPreferences,
      },
    );
    final visibleAfterBack = previous.copyWith(
      currentStepId: OnboardingStepId.profileBasics,
      profile: previous.profile.copyWith(currentStepId: ProfileStepId.name),
      completedStepIds: const {},
    );

    final persisted = resolver(
      entryPath: OnboardingEntryPath.resumeDraft,
      visibleDraft: visibleAfterBack,
      previousPersistedDraft: previous,
    );

    expect(persisted.currentStepId, OnboardingStepId.targets);
    expect(persisted.targets.currentStepId, TargetStepId.waterTarget);
    expect(
      persisted.completedStepIds,
      containsAll({
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.workoutPreferences,
      }),
    );
  });

  test('removed flow step reconciles checkpoint to the visible valid boundary',
      () {
    final previous = OnboardingDraft(
      selectedMode: AppMode.hybrid,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.stayFit,
      ),
      workoutIntroChoice: WorkoutIntroChoice.setupNow,
      currentStepId: OnboardingStepId.workoutPreferences,
      profile: _validProfile(),
      workout: _validWorkout(),
      completedStepIds: const {
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.workoutIntro,
      },
    );
    final visibleAfterBranchChange = previous.copyWith(
      workoutIntroChoice: WorkoutIntroChoice.later,
      currentStepId: OnboardingStepId.workoutIntro,
      completedStepIds: const {
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
      },
    );

    final persisted = resolver(
      entryPath: OnboardingEntryPath.resumeDraft,
      visibleDraft: visibleAfterBranchChange,
      previousPersistedDraft: previous,
    );

    expect(persisted.currentStepId, OnboardingStepId.workoutIntro);
    expect(
      persisted.completedStepIds,
      containsAll({
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
      }),
    );
  });
}

ProfileOnboardingDraft _validProfile({
  ProfileStepId currentStepId = ProfileStepId.healthConditions,
}) {
  return ProfileOnboardingDraft(
    currentStepId: currentStepId,
    name: 'Tio User',
    gender: ProfileGender.other,
    goals: const {ProfileGoal.keepFit},
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 68,
    targetWeightDirection: GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _validWorkout() {
  return const WorkoutOnboardingDraft(
    currentStepId: WorkoutStepId.specialEvent,
    gymAccess: WorkoutGymAccess.gym,
    experienceLevel: WorkoutExperienceLevel.beginner,
    focusAreas: {WorkoutFocusArea.fullBody},
    trainingDays: {WorkoutTrainingDay.monday},
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.fullBody,
  );
}

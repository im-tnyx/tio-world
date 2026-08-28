import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  test('O8E integrates Back-safe Review resume with Hybrid branch reconciliation',
      () async {
    final initial = OnboardingDraft(
      status: OnboardingStatus.inProgress,
      selectedMode: AppMode.hybrid,
      workoutIntroChoice: WorkoutIntroChoice.setupNow,
      goalSelection: const GoalIntentSelection(
        primaryGoal: GoalIntent.loseWeight,
        supportingGoal: GoalIntent.improveEndurance,
      ),
      currentStepId: OnboardingStepId.review,
      completedStepIds: const {
        OnboardingStepId.profileBasics,
        OnboardingStepId.bodyGoal,
        OnboardingStepId.wellnessGoals,
        OnboardingStepId.nutritionProfile,
        OnboardingStepId.workoutIntro,
        OnboardingStepId.workoutProfile,
        OnboardingStepId.workoutTargets,
        OnboardingStepId.nutritionGoals,
        OnboardingStepId.healthConnections,
      },
      profile: _validProfile(),
      workout: _validWorkout(),
      targets: const TargetsOnboardingDraft(
        currentStepId: TargetStepId.nutritionTarget,
        goalPaceKgPerWeek: 0.5,
      ),
    );

    final delegate = InMemoryOnboardingDraftRepository(
      initialSnapshot: OnboardingDraftSnapshot(draft: initial),
    );
    final firstRepository = ResumePreservingOnboardingDraftRepository(
      delegate: delegate,
    );
    final firstController = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      draftRepository: firstRepository,
    );

    await firstController.hydrateDraft();
    expect(firstController.state.stepId, OnboardingStepId.review);
    expect(
      firstController.state.flowPlan.contains(OnboardingStepId.workoutProfile),
      isTrue,
    );
    expect(
      firstController.state.flowPlan.contains(OnboardingStepId.workoutTargets),
      isTrue,
    );

    firstController.previous();
    expect(firstController.state.stepId, OnboardingStepId.healthConnections);

    final durableAfterBack = await firstRepository.loadDraft();
    expect(durableAfterBack, isNotNull);
    expect(durableAfterBack!.draft.currentStepId, OnboardingStepId.review);

    final secondRepository = ResumePreservingOnboardingDraftRepository(
      delegate: delegate,
    );
    final resumed = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      draftRepository: secondRepository,
    );
    await resumed.hydrateDraft();

    expect(resumed.state.stepId, OnboardingStepId.review);
    expect(resumed.state.draft.workout.specialEvent, '10K race');

    resumed.selectWorkoutIntroChoice(WorkoutIntroChoice.later);

    expect(resumed.state.stepId, OnboardingStepId.review);
    expect(resumed.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);
    expect(
      resumed.state.flowPlan.contains(OnboardingStepId.workoutProfile),
      isFalse,
    );
    expect(
      resumed.state.flowPlan.contains(OnboardingStepId.workoutTargets),
      isFalse,
    );
    expect(
      resumed.state.completedStepIds,
      isNot(contains(OnboardingStepId.workoutProfile)),
    );
    expect(
      resumed.state.completedStepIds,
      isNot(contains(OnboardingStepId.workoutTargets)),
    );
    expect(resumed.state.draft.workout.gymAccess, WorkoutGymAccess.gym);
    expect(resumed.state.draft.workout.specialEvent, '10K race');

    final durableAfterBranchChange = await secondRepository.loadDraft();
    expect(durableAfterBranchChange, isNotNull);
    expect(
      durableAfterBranchChange!.draft.workoutIntroChoice,
      WorkoutIntroChoice.later,
    );
    expect(
      durableAfterBranchChange.draft.completedStepIds,
      isNot(contains(OnboardingStepId.workoutProfile)),
    );
    expect(durableAfterBranchChange.draft.workout.specialEvent, '10K race');

    final thirdRepository = ResumePreservingOnboardingDraftRepository(
      delegate: delegate,
    );
    final rehydrated = OnboardingController(
      entryPath: OnboardingEntryPath.resumeDraft,
      draftRepository: thirdRepository,
    );
    await rehydrated.hydrateDraft();

    expect(rehydrated.state.stepId, OnboardingStepId.review);
    expect(rehydrated.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);
    expect(
      rehydrated.state.flowPlan.contains(OnboardingStepId.workoutProfile),
      isFalse,
    );
    expect(
      rehydrated.state.flowPlan.contains(OnboardingStepId.workoutTargets),
      isFalse,
    );
    expect(rehydrated.state.draft.workout.gymAccess, WorkoutGymAccess.gym);
    expect(rehydrated.state.draft.workout.specialEvent, '10K race');
  });
}

ProfileOnboardingDraft _validProfile() {
  return ProfileOnboardingDraft(
    currentStepId: ProfileStepId.healthConditions,
    name: 'Integrated User',
    gender: ProfileGender.other,
    dateOfBirth: DateTime(2000, 1, 1),
    heightCm: 171,
    currentWeightKg: 70,
    targetWeightKg: 65,
    targetWeightDirection: GoalWeightDirection.loss,
    activityLevel: ProfileActivityLevel.active,
    healthConditions: const {ProfileHealthCondition.none},
  );
}

WorkoutOnboardingDraft _validWorkout() {
  return const WorkoutOnboardingDraft(
    currentStepId: WorkoutStepId.specialEvent,
    gymAccess: WorkoutGymAccess.gym,
    experienceLevel: WorkoutExperienceLevel.intermediate,
    focusAreas: {WorkoutFocusArea.fullBody},
    trainingDays: {
      WorkoutTrainingDay.monday,
      WorkoutTrainingDay.thursday,
    },
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.fullBody,
    healthConcerns: 'None',
    specialEvent: '10K race',
  );
}

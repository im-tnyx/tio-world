import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O8C edit-back invalidation and mode reconciliation', () {
    test('Goal semantic edit invalidates Body and dependent Workout Targets only',
        () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.hybrid,
          workoutIntroChoice: WorkoutIntroChoice.setupNow,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
            supportingGoal: GoalIntent.improveEndurance,
          ),
          currentStepId: OnboardingStepId.bodyGoal,
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
          profile: ProfileOnboardingDraft(
            currentStepId: ProfileStepId.goal,
            currentWeightKg: 70,
            targetWeightKg: 64,
            targetWeightDirection: GoalWeightDirection.loss,
          ),
          workout: _seededWorkout(),
        ),
      );

      controller.tapGoalIntent(GoalIntent.stayFit);

      expect(
        controller.state.draft.goalSelection,
        const GoalIntentSelection(primaryGoal: GoalIntent.stayFit),
      );
      expect(controller.state.weightGoalDirection, isNull);
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.bodyGoal)),
      );
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.workoutTargets)),
      );
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.workoutProfile),
      );
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.nutritionGoals),
      );
      expect(controller.state.draft.profile.targetWeightKg, 64);
      expect(
        controller.state.draft.profile.targetWeightDirection,
        GoalWeightDirection.loss,
      );
    });

    test('Hybrid setupNow to later removes active Workout completion but preserves data',
        () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.hybrid,
          workoutIntroChoice: WorkoutIntroChoice.setupNow,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
            supportingGoal: GoalIntent.improveEndurance,
          ),
          currentStepId: OnboardingStepId.workoutIntro,
          completedStepIds: const {
            OnboardingStepId.profileBasics,
            OnboardingStepId.bodyGoal,
            OnboardingStepId.wellnessGoals,
            OnboardingStepId.nutritionProfile,
            OnboardingStepId.workoutIntro,
            OnboardingStepId.workoutProfile,
            OnboardingStepId.workoutTargets,
          },
          workout: _seededWorkout(),
        ),
      );

      controller.selectWorkoutIntroChoice(WorkoutIntroChoice.later);

      expect(controller.state.draft.workoutIntroChoice, WorkoutIntroChoice.later);
      expect(
        controller.state.flowPlan.contains(OnboardingStepId.workoutProfile),
        isFalse,
      );
      expect(
        controller.state.flowPlan.contains(OnboardingStepId.workoutTargets),
        isFalse,
      );
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.workoutProfile)),
      );
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.workoutTargets)),
      );
      expect(controller.state.draft.workout.gymAccess, WorkoutGymAccess.gym);
      expect(controller.state.draft.workout.specialEvent, '10K race');
    });

    test('Hybrid later to setupNow restores Workout branch without fabricated completion',
        () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.hybrid,
          workoutIntroChoice: WorkoutIntroChoice.later,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
            supportingGoal: GoalIntent.improveEndurance,
          ),
          currentStepId: OnboardingStepId.workoutIntro,
          completedStepIds: const {
            OnboardingStepId.profileBasics,
            OnboardingStepId.bodyGoal,
            OnboardingStepId.wellnessGoals,
            OnboardingStepId.nutritionProfile,
            OnboardingStepId.workoutIntro,
          },
          workout: _seededWorkout(),
        ),
      );

      controller.selectWorkoutIntroChoice(WorkoutIntroChoice.setupNow);

      expect(
        controller.state.flowPlan.contains(OnboardingStepId.workoutProfile),
        isTrue,
      );
      expect(
        controller.state.flowPlan.contains(OnboardingStepId.workoutTargets),
        isTrue,
      );
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.workoutProfile)),
      );
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.workoutTargets)),
      );
      expect(controller.state.draft.workout.gymAccess, WorkoutGymAccess.gym);
      expect(controller.state.draft.workout.specialEvent, '10K race');
    });

    test('Hybrid to Nutrition filters Workout checkpoints, preserves data and reconciles Goal',
        () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
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
          profile: const ProfileOnboardingDraft(
            currentStepId: ProfileStepId.healthConditions,
          ),
          workout: _seededWorkout(),
        ),
      );

      controller.selectMode(AppMode.nutrition);

      expect(controller.state.draft.selectedMode, AppMode.nutrition);
      expect(
        controller.state.draft.goalSelection,
        const GoalIntentSelection(primaryGoal: GoalIntent.loseWeight),
      );
      expect(controller.state.stepId, OnboardingStepId.bodyGoal);
      expect(controller.state.draft.profile.currentStepId, ProfileStepId.goal);
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.workoutIntro)),
      );
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.workoutProfile)),
      );
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.workoutTargets)),
      );
      expect(controller.state.draft.workout.gymAccess, WorkoutGymAccess.gym);
      expect(controller.state.draft.workout.specialEvent, '10K race');
    });

    test('harmless common Profile edit invalidates Profile only', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.nutrition,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.maintainWeight,
          ),
          currentStepId: OnboardingStepId.profileBasics,
          completedStepIds: const {
            OnboardingStepId.profileBasics,
            OnboardingStepId.bodyGoal,
            OnboardingStepId.wellnessGoals,
            OnboardingStepId.nutritionProfile,
            OnboardingStepId.nutritionGoals,
            OnboardingStepId.healthConnections,
          },
          profile: const ProfileOnboardingDraft(
            currentStepId: ProfileStepId.name,
            name: 'Old Name',
          ),
        ),
      );

      controller.updateProfileName('New Name');

      expect(controller.state.draft.profile.name, 'New Name');
      expect(
        controller.state.completedStepIds,
        isNot(contains(OnboardingStepId.profileBasics)),
      );
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.bodyGoal),
      );
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.wellnessGoals),
      );
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.nutritionProfile),
      );
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.nutritionGoals),
      );
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.healthConnections),
      );
    });
  });
}

WorkoutOnboardingDraft _seededWorkout() {
  return const WorkoutOnboardingDraft(
    currentStepId: WorkoutStepId.specialEvent,
    gymAccess: WorkoutGymAccess.gym,
    experienceLevel: WorkoutExperienceLevel.intermediate,
    focusAreas: {WorkoutFocusArea.fullBody},
    trainingDays: {WorkoutTrainingDay.monday, WorkoutTrainingDay.thursday},
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.fullBody,
    specialEvent: '10K race',
  );
}

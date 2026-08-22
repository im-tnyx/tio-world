import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O5C Nutrition Goals runtime ownership', () {
    test('all active modes use nutritionGoals and never legacy targets', () {
      const planner = BuildOnboardingFlowUseCase();

      for (final mode in AppMode.values) {
        final plan = planner(
          entryPath: OnboardingEntryPath.firstRun,
          mode: mode,
          workoutIntroChoice: mode == AppMode.hybrid
              ? WorkoutIntroChoice.setupNow
              : null,
        );

        expect(plan.stepIds, contains(OnboardingStepId.nutritionGoals));
        expect(plan.stepIds, isNot(contains(OnboardingStepId.targets)));
        expect(
          plan.definitionFor(OnboardingStepId.nutritionGoals).section,
          OnboardingSectionId.nutritionGoals,
        );
      }
    });

    test('legacy targets nutrition cursor normalizes losslessly', () {
      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.targets,
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.nutritionTarget,
          dailySteps: 12345,
          waterMl: 2750,
          goalPaceKgPerWeek: 0.75,
        ),
        completedStepIds: const {
          OnboardingStepId.profileBasics,
          OnboardingStepId.bodyGoal,
          OnboardingStepId.wellnessGoals,
          OnboardingStepId.workoutPreferences,
          OnboardingStepId.targets,
        },
      );

      expect(draft.currentStepId, OnboardingStepId.nutritionGoals);
      expect(draft.targets.currentStepId, TargetStepId.nutritionTarget);
      expect(draft.targets.dailySteps, 12345);
      expect(draft.targets.waterMl, 2750);
      expect(draft.targets.goalPaceKgPerWeek, 0.75);
      expect(
        draft.completedStepIds,
        contains(OnboardingStepId.nutritionGoals),
      );
      expect(
        draft.completedStepIds,
        isNot(contains(OnboardingStepId.targets)),
      );
    });

    test('active nutritionGoals always owns the Nutrition Target child', () {
      final draft = OnboardingDraft(
        selectedMode: AppMode.workout,
        currentStepId: OnboardingStepId.nutritionGoals,
        targets: const TargetsOnboardingDraft(
          currentStepId: TargetStepId.waterTarget,
          waterMl: 3100,
        ),
      );

      expect(draft.currentStepId, OnboardingStepId.nutritionGoals);
      expect(draft.targets.currentStepId, TargetStepId.nutritionTarget);
      expect(draft.targets.waterMl, 3100);
    });

    test('controller exposes Review action and navigates Nutrition Goals to Review',
        () async {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.workout,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.stayFit,
          ),
          currentStepId: OnboardingStepId.targets,
          profile: _validProfile(),
          workout: _validWorkout(),
          targets: const TargetsOnboardingDraft(
            currentStepId: TargetStepId.nutritionTarget,
          ),
        ),
      );

      expect(controller.state.stepId, OnboardingStepId.nutritionGoals);
      expect(controller.state.currentSection, OnboardingSectionId.nutritionGoals);
      expect(controller.state.primaryActionLabel, 'Review');
      expect(controller.state.progressStepNumber, greaterThan(0));

      await controller.next(onFinish: (_) async {});

      expect(controller.state.stepId, OnboardingStepId.review);
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.nutritionGoals),
      );
    });

    test('Back from Nutrition Goals restores preceding Workout child', () {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.workout,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.stayFit,
          ),
          currentStepId: OnboardingStepId.nutritionGoals,
          profile: _validProfile(),
          workout: _validWorkout(currentStepId: WorkoutStepId.specialEvent),
          targets: const TargetsOnboardingDraft(
            currentStepId: TargetStepId.nutritionTarget,
          ),
        ),
      );

      controller.previous();

      expect(controller.state.stepId, OnboardingStepId.workoutTargets);
      expect(
        controller.state.draft.workout.currentStepId,
        WorkoutStepId.specialEvent,
      );
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

WorkoutOnboardingDraft _validWorkout({
  WorkoutStepId currentStepId = WorkoutStepId.gymAccess,
}) {
  return WorkoutOnboardingDraft(
    currentStepId: currentStepId,
    gymAccess: WorkoutGymAccess.gym,
    experienceLevel: WorkoutExperienceLevel.beginner,
    focusAreas: const {WorkoutFocusArea.legs},
    trainingDays: const {
      WorkoutTrainingDay.monday,
      WorkoutTrainingDay.wednesday,
    },
    workoutDuration: WorkoutDuration.sixtyMinutes,
    workoutSplit: WorkoutSplit.auto,
  );
}

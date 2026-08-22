import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const buildProgressPlan = BuildOnboardingProgressPlanUseCase();
  const buildFlowPlan = BuildOnboardingFlowUseCase();
  const buildWorkoutPlan = BuildWorkoutFlowPlanUseCase();

  group('BuildOnboardingProgressPlanUseCase', () {
    test('workout mode with gym access derives 25 product-onboarding screens', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      // O4B preserves the visible denominator while moving Bridge/Steps/Sleep/
      // Water from Targets progress ownership into the Wellness boundary.
      expect(progressPlan.totalSteps, 25);
      expect(progressPlan.items.first, isA<ProfileProgressItem>());
      expect(progressPlan.items.whereType<BodyGoalProgressItem>(), hasLength(4));
      expect(progressPlan.items.whereType<WellnessProgressItem>(), hasLength(4));
      expect(progressPlan.items.whereType<TargetsProgressItem>(), hasLength(1));
      expect(
        progressPlan.items.whereType<WellnessProgressItem>().map((e) => e.stepId),
        const [
          TargetStepId.bridge,
          TargetStepId.stepTarget,
          TargetStepId.sleepTarget,
          TargetStepId.waterTarget,
        ],
      );
      expect(
        progressPlan.items.whereType<TargetsProgressItem>().map((e) => e.stepId),
        const [TargetStepId.nutritionTarget],
      );
      expect(progressPlan.items.last, isA<ReviewProgressItem>());
      expect(
        progressPlan.items.whereType<WorkoutProgressItem>().map((e) => e.stepId),
        isNot(contains(WorkoutStepId.equipment)),
      );
    });

    test('workout mode with home gym access derives 26 screens (includes equipment)', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.home);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      expect(progressPlan.totalSteps, 26);
      expect(
        progressPlan.items.whereType<WorkoutProgressItem>().map((e) => e.stepId),
        contains(WorkoutStepId.equipment),
      );
    });

    test('nutrition mode derives 17 product-onboarding screens', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
      );
      final workoutPlan = buildWorkoutPlan();
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      expect(progressPlan.totalSteps, 17);
      expect(progressPlan.items.whereType<WorkoutProgressItem>(), isEmpty);
      expect(progressPlan.items.whereType<NutritionIntroProgressItem>(), isEmpty);
      expect(progressPlan.items.whereType<WellnessProgressItem>(), hasLength(4));
      expect(progressPlan.items.whereType<TargetsProgressItem>(), hasLength(1));
    });

    test('hybrid setupNow derives 26 (gym) / 27 (home) screens', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
      );
      final gymWorkoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final homeWorkoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.home);

      final gymProgressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: gymWorkoutPlan,
      );
      final homeProgressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: homeWorkoutPlan,
      );

      expect(gymProgressPlan.totalSteps, 26);
      expect(homeProgressPlan.totalSteps, 27);
    });

    test('hybrid later derives 18 screens (skips workout preferences)', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );
      final workoutPlan = buildWorkoutPlan();
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      expect(progressPlan.totalSteps, 18);
      expect(progressPlan.items.whereType<WorkoutProgressItem>(), isEmpty);
      expect(progressPlan.items.whereType<WorkoutIntroProgressItem>(), hasLength(1));
    });

    test('every common Profile child screen strictly increases progress', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      double previousProgress = 0.0;
      for (final profileStep in ProfileFlowPlan.orderedSteps) {
        final progress = progressPlan.progressFor(
          stepId: OnboardingStepId.profileBasics,
          profileStepId: profileStep,
          workoutStepId: WorkoutStepId.gymAccess,
          targetStepId: TargetStepId.bridge,
        );

        expect(progress, greaterThan(previousProgress),
            reason: 'Profile step $profileStep must increase progress');
        previousProgress = progress;
      }
    });

    test('Body Goal children follow common Profile monotonically', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym),
      );

      var previousProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.profileBasics,
        profileStepId: ProfileStepId.healthConditions,
        workoutStepId: WorkoutStepId.gymAccess,
        targetStepId: TargetStepId.bridge,
      );

      for (final bodyStep in BodyGoalFlowPlan.orderedSteps) {
        final progress = progressPlan.progressFor(
          stepId: OnboardingStepId.bodyGoal,
          profileStepId: bodyStep,
          workoutStepId: WorkoutStepId.gymAccess,
          targetStepId: TargetStepId.bridge,
        );
        expect(progress, greaterThan(previousProgress),
            reason: 'Body Goal step $bodyStep must follow common Profile');
        previousProgress = progress;
      }
    });

    test('Wellness children follow Body Goal monotonically', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym),
      );

      var previousProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.bodyGoal,
        profileStepId: ProfileStepId.goalPace,
        workoutStepId: WorkoutStepId.gymAccess,
        targetStepId: TargetStepId.bridge,
      );

      for (final wellnessStep in WellnessFlowPlan.orderedSteps) {
        final progress = progressPlan.progressFor(
          stepId: OnboardingStepId.wellnessGoals,
          profileStepId: ProfileStepId.goalPace,
          workoutStepId: WorkoutStepId.gymAccess,
          targetStepId: wellnessStep,
        );
        expect(progress, greaterThan(previousProgress),
            reason: 'Wellness step $wellnessStep must follow Body Goal');
        previousProgress = progress;
      }
    });

    test('every Workout child screen strictly increases progress monotonically', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.home);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      double previousProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.wellnessGoals,
        profileStepId: ProfileStepId.goalPace,
        workoutStepId: WorkoutStepId.gymAccess,
        targetStepId: TargetStepId.waterTarget,
      );

      for (final workoutStep in workoutPlan.steps) {
        final progress = progressPlan.progressFor(
          stepId: OnboardingStepId.workoutPreferences,
          profileStepId: ProfileStepId.goalPace,
          workoutStepId: workoutStep,
          targetStepId: TargetStepId.waterTarget,
        );

        expect(progress, greaterThan(previousProgress),
            reason: 'Step $workoutStep must increase progress over $previousProgress');
        previousProgress = progress;
      }
    });

    test('active Nutrition Target follows the preceding mode-specific section', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      final previousProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.workoutPreferences,
        profileStepId: ProfileStepId.goalPace,
        workoutStepId: workoutPlan.steps.last,
        targetStepId: TargetStepId.waterTarget,
      );
      final targetProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.targets,
        profileStepId: ProfileStepId.goalPace,
        workoutStepId: workoutPlan.steps.last,
        targetStepId: TargetStepId.nutritionTarget,
      );

      expect(targetProgress, greaterThan(previousProgress));
    });

    test('Review screen reaches exactly 1.0 progress', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      final progress = progressPlan.progressFor(
        stepId: OnboardingStepId.review,
        profileStepId: ProfileStepId.goalPace,
        workoutStepId: WorkoutStepId.specialEvent,
        targetStepId: TargetStepId.nutritionTarget,
      );

      expect(progress, 1.0);
    });

    test('AppMode screen returns 0.0 progress and index -1', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      expect(
        progressPlan.indexOfCurrentScreen(
          stepId: OnboardingStepId.mode,
          profileStepId: ProfileStepId.name,
          workoutStepId: WorkoutStepId.gymAccess,
          targetStepId: TargetStepId.bridge,
        ),
        -1,
      );
      expect(
        progressPlan.progressFor(
          stepId: OnboardingStepId.mode,
          profileStepId: ProfileStepId.name,
          workoutStepId: WorkoutStepId.gymAccess,
          targetStepId: TargetStepId.bridge,
        ),
        0.0,
      );
    });

    test('going backward across the Profile/Body boundary decreases progress', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym),
      );

      final goalProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.bodyGoal,
        profileStepId: ProfileStepId.goal,
        workoutStepId: WorkoutStepId.gymAccess,
        targetStepId: TargetStepId.bridge,
      );

      final healthProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.profileBasics,
        profileStepId: ProfileStepId.healthConditions,
        workoutStepId: WorkoutStepId.gymAccess,
        targetStepId: TargetStepId.bridge,
      );

      expect(healthProgress, lessThan(goalProgress));
    });

    test('dynamically changing gym to home recalculates total without phantom slots', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );

      final gymPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym),
      );
      expect(gymPlan.totalSteps, 25);

      final homePlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: buildWorkoutPlan(gymAccess: WorkoutGymAccess.home),
      );
      expect(homePlan.totalSteps, 26);

      final backToGymPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym),
      );
      expect(backToGymPlan.totalSteps, 25);
    });
  });
}

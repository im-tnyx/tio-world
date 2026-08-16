import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  const buildProgressPlan = BuildOnboardingProgressPlanUseCase();
  const buildFlowPlan = BuildOnboardingFlowUseCase();
  const buildWorkoutPlan = BuildWorkoutFlowPlanUseCase();

  group('BuildOnboardingProgressPlanUseCase', () {
    test('workout mode with gym access derives 25 total screens', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      // 10 (Profile) + 8 (Workout) + 6 (Targets) + 1 (Review) = 25
      expect(progressPlan.totalSteps, 25);
      expect(progressPlan.items.first, isA<ProfileProgressItem>());
      expect(progressPlan.items.last, isA<ReviewProgressItem>());
      expect(
        progressPlan.items.whereType<WorkoutProgressItem>().map((e) => e.stepId),
        isNot(contains(WorkoutStepId.equipment)),
      );
    });

    test('workout mode with home gym access derives 26 total screens (includes equipment)', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.home);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      // 10 (Profile) + 9 (Workout) + 6 (Targets) + 1 (Review) = 26
      expect(progressPlan.totalSteps, 26);
      expect(
        progressPlan.items.whereType<WorkoutProgressItem>().map((e) => e.stepId),
        contains(WorkoutStepId.equipment),
      );
    });

    test('nutrition mode derives 17 total screens', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
      );
      final workoutPlan = buildWorkoutPlan();
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      // 10 (Profile) + 6 (Targets) + 1 (Review) = 17
      expect(progressPlan.totalSteps, 17);
      expect(progressPlan.items.whereType<WorkoutProgressItem>(), isEmpty);
      expect(progressPlan.items.whereType<NutritionIntroProgressItem>(), isEmpty);
    });

    test('hybrid mode with setupNow derives 26 (gym) / 27 (home) screens', () {
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

      // 10 (Profile) + 1 (WorkoutIntro) + 8 (Workout) + 6 (Targets) + 1 (Review) = 26
      expect(gymProgressPlan.totalSteps, 26);
      // 10 (Profile) + 1 (WorkoutIntro) + 9 (Workout) + 6 (Targets) + 1 (Review) = 27
      expect(homeProgressPlan.totalSteps, 27);
    });

    test('hybrid mode with later derives 18 screens (skips workout preferences)', () {
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

      // 10 (Profile) + 1 (WorkoutIntro) + 6 (Targets) + 1 (Review) = 18
      expect(progressPlan.totalSteps, 18);
      expect(progressPlan.items.whereType<WorkoutProgressItem>(), isEmpty);
      expect(progressPlan.items.whereType<WorkoutIntroProgressItem>(), hasLength(1));
    });

    test('every Profile child screen strictly increases progress monotonically', () {
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
      for (final profileStep in ProfileStepId.values) {
        final progress = progressPlan.progressFor(
          stepId: OnboardingStepId.profileBasics,
          profileStepId: profileStep,
          workoutStepId: WorkoutStepId.gymAccess,
          targetStepId: TargetStepId.bridge,
        );

        expect(progress, greaterThan(previousProgress),
            reason: 'Step $profileStep must increase progress over $previousProgress');
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
        stepId: OnboardingStepId.mobile,
        profileStepId: ProfileStepId.healthConditions,
        workoutStepId: WorkoutStepId.gymAccess,
        targetStepId: TargetStepId.bridge,
      );

      for (final workoutStep in workoutPlan.steps) {
        final progress = progressPlan.progressFor(
          stepId: OnboardingStepId.workoutPreferences,
          profileStepId: ProfileStepId.healthConditions,
          workoutStepId: workoutStep,
          targetStepId: TargetStepId.bridge,
        );

        expect(progress, greaterThan(previousProgress),
            reason: 'Step $workoutStep must increase progress over $previousProgress');
        previousProgress = progress;
      }
    });

    test('every Targets child screen strictly increases progress monotonically', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      double previousProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.workoutPreferences,
        profileStepId: ProfileStepId.healthConditions,
        workoutStepId: WorkoutStepId.specialEvent,
        targetStepId: TargetStepId.bridge,
      );

      for (final targetStep in TargetsFlowPlan.orderedSteps) {
        final progress = progressPlan.progressFor(
          stepId: OnboardingStepId.targets,
          profileStepId: ProfileStepId.healthConditions,
          workoutStepId: WorkoutStepId.specialEvent,
          targetStepId: targetStep,
        );

        expect(progress, greaterThan(previousProgress),
            reason: 'Target step $targetStep must increase progress over $previousProgress');
        previousProgress = progress;
      }
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
        profileStepId: ProfileStepId.healthConditions,
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

    test('going backward decreases derived progress naturally without mutable state', () {
      final flowPlan = buildFlowPlan(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      final workoutPlan = buildWorkoutPlan(gymAccess: WorkoutGymAccess.gym);
      final progressPlan = buildProgressPlan(
        flowPlan: flowPlan,
        workoutFlowPlan: workoutPlan,
      );

      final goalProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.profileBasics,
        profileStepId: ProfileStepId.goal,
        workoutStepId: WorkoutStepId.gymAccess,
        targetStepId: TargetStepId.bridge,
      );

      final genderProgress = progressPlan.progressFor(
        stepId: OnboardingStepId.profileBasics,
        profileStepId: ProfileStepId.gender,
        workoutStepId: WorkoutStepId.gymAccess,
        targetStepId: TargetStepId.bridge,
      );

      expect(genderProgress, lessThan(goalProgress));
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

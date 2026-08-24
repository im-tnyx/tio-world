import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_workout/workout.dart' as workout_owner;
import 'package:tio_shared/shared.dart';

void main() {
  group('O6C Workout Profile + Targets runtime', () {
    const planner = BuildOnboardingFlowUseCase();
    const workoutPlanner = BuildWorkoutFlowPlanUseCase();

    test('mode matrix activates Profile then Targets only when Workout is active',
        () {
      final workout = planner(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      expect(
        workout.stepIds.indexOf(OnboardingStepId.workoutTargets),
        workout.stepIds.indexOf(OnboardingStepId.workoutProfile) + 1,
      );

      final hybridNow = planner(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
      );
      expect(
        hybridNow.stepIds.sublist(
          hybridNow.stepIds.indexOf(OnboardingStepId.workoutIntro),
          hybridNow.stepIds.indexOf(OnboardingStepId.workoutTargets) + 1,
        ),
        const [
          OnboardingStepId.workoutIntro,
          OnboardingStepId.workoutProfile,
          OnboardingStepId.workoutTargets,
        ],
      );

      final nutrition = planner(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
      );
      expect(nutrition.stepIds, isNot(contains(OnboardingStepId.workoutProfile)));
      expect(nutrition.stepIds, isNot(contains(OnboardingStepId.workoutTargets)));

      final hybridLater = planner(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );
      expect(
        hybridLater.stepIds,
        isNot(contains(OnboardingStepId.workoutProfile)),
      );
      expect(
        hybridLater.stepIds,
        isNot(contains(OnboardingStepId.workoutTargets)),
      );
    });

    test('Workout child ownership is contiguous and owner-correct', () {
      final plan = workoutPlanner(gymAccess: WorkoutGymAccess.home);
      expect(
        plan.profileSteps,
        const [
          WorkoutStepId.gymAccess,
          WorkoutStepId.equipment,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.healthConcerns,
        ],
      );
      expect(
        plan.targetSteps,
        const [
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
          WorkoutStepId.workoutSplit,
          WorkoutStepId.specialEvent,
        ],
      );
      expect(plan.steps, [...plan.profileSteps, ...plan.targetSteps]);
    });

    test('pre-v6 broad Targets cursor and completion migrate to split owners', () {
      const mapper = OnboardingDraftSnapshotDtoMapper();
      final snapshot = mapper.fromJson({
        'schema_version': 5,
        'status': 'inProgress',
        'selected_mode': 'workout',
        'current_step_id': 'workoutProfile',
        'completed_step_ids': ['wellnessGoals', 'workoutProfile'],
        'workout': {
          'current_step_id': 'trainingDays',
          'gym_access': 'gym',
          'experience_level': 'beginner',
          'focus_areas': ['fullBody'],
          'training_days': ['monday'],
        },
        'updated_at': '2026-08-22T00:00:00Z',
      });

      expect(snapshot.draft.currentStepId, OnboardingStepId.workoutTargets);
      expect(snapshot.draft.workout.currentStepId, WorkoutStepId.trainingDays);
      expect(
        snapshot.draft.completedStepIds,
        containsAll(<OnboardingStepId>[
          OnboardingStepId.workoutProfile,
          OnboardingStepId.workoutTargets,
        ]),
      );
    });

    test('v6 partial Workout Profile completion stays partial', () {
      const mapper = OnboardingDraftSnapshotDtoMapper();
      final snapshot = mapper.fromJson({
        'schema_version': OnboardingDraftSnapshot.currentSchemaVersion,
        'status': 'inProgress',
        'selected_mode': 'workout',
        'current_step_id': 'workoutProfile',
        'completed_step_ids': ['workoutProfile'],
        'workout': {
          'current_step_id': 'healthConcerns',
          'gym_access': 'gym',
        },
        'updated_at': '2026-08-22T00:00:00Z',
      });

      expect(OnboardingDraftSnapshot.currentSchemaVersion, 6);
      expect(snapshot.draft.currentStepId, OnboardingStepId.workoutProfile);
      expect(
        snapshot.draft.completedStepIds,
        contains(OnboardingStepId.workoutProfile),
      );
      expect(
        snapshot.draft.completedStepIds,
        isNot(contains(OnboardingStepId.workoutTargets)),
      );
    });

    test('next/back crosses Profile and Targets boundary without duplicate screen',
        () async {
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.resumeDraft,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.workout,
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.stayFit,
          ),
          currentStepId: OnboardingStepId.workoutProfile,
          workout: const WorkoutOnboardingDraft(
            currentStepId: WorkoutStepId.healthConcerns,
            gymAccess: WorkoutGymAccess.gym,
            experienceLevel: WorkoutExperienceLevel.beginner,
            focusAreas: {WorkoutFocusArea.fullBody},
          ),
        ),
      );
      addTearDown(controller.dispose);

      final profileProgress = controller.state.progressStepNumber;
      await controller.next(onFinish: (_) async {});

      expect(controller.state.stepId, OnboardingStepId.workoutTargets);
      expect(
        controller.state.draft.workout.currentStepId,
        WorkoutStepId.trainingDays,
      );
      expect(controller.state.progressStepNumber, profileProgress + 1);
      expect(
        controller.state.completedStepIds,
        contains(OnboardingStepId.workoutProfile),
      );

      controller.previous();
      expect(controller.state.stepId, OnboardingStepId.workoutProfile);
      expect(
        controller.state.draft.workout.currentStepId,
        WorkoutStepId.healthConcerns,
      );
    });
  });

  group('WorkoutTargetsMapper', () {
    const mapper = WorkoutTargetsMapper();

    test('uses Workout-relative rank after filtering Body intent', () {
      final data = mapper.map(
        OnboardingDraft(
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
            supportingGoal: GoalIntent.buildMuscle,
          ),
          workout: const WorkoutOnboardingDraft(
            trainingDays: {
              WorkoutTrainingDay.monday,
              WorkoutTrainingDay.wednesday,
            },
            workoutDuration: WorkoutDuration.ninetyMinutes,
            workoutSplit: WorkoutSplit.ppl,
            specialEvent: '  Local race  ',
          ),
        ),
      );

      expect(data.primaryWorkoutGoal, workout_owner.WorkoutTargetGoal.buildMuscle);
      expect(data.primaryGoalRank, 1);
      expect(data.supportingWorkoutGoal, isNull);
      expect(data.supportingGoalRank, isNull);
      expect(
        data.trainingDays,
        {
          workout_owner.WorkoutTrainingDay.monday,
          workout_owner.WorkoutTrainingDay.wednesday,
        },
      );
      expect(data.preferredDurationMins, 90);
      expect(data.splitProgram, workout_owner.WorkoutSplit.ppl);
      expect(data.specialEvent, 'Local race');
      expect(data.specialEventDate, isNull);
    });

    test('Body plus two training goals preserve both Workout priorities', () {
      final data = mapper.map(
        OnboardingDraft(
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
            supportingGoal: GoalIntent.buildMuscle,
            tertiaryGoal: GoalIntent.getStronger,
          ),
        ),
      );

      expect(data.primaryWorkoutGoal, workout_owner.WorkoutTargetGoal.buildMuscle);
      expect(data.primaryGoalRank, 1);
      expect(data.supportingWorkoutGoal, workout_owner.WorkoutTargetGoal.getStronger);
      expect(data.supportingGoalRank, 2);
    });

    test('Body-only goals and Auto duration fabricate nothing', () {
      final data = mapper.map(
        OnboardingDraft(
          goalSelection: const GoalIntentSelection(
            primaryGoal: GoalIntent.loseWeight,
            supportingGoal: GoalIntent.maintainWeight,
          ),
          workout: const WorkoutOnboardingDraft(
            workoutDuration: WorkoutDuration.auto,
            specialEvent: '   ',
          ),
        ),
      );

      expect(data.primaryWorkoutGoal, isNull);
      expect(data.primaryGoalRank, isNull);
      expect(data.supportingWorkoutGoal, isNull);
      expect(data.supportingGoalRank, isNull);
      expect(data.preferredDurationMins, isNull);
      expect(data.specialEvent, isNull);
      expect(data.specialEventDate, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O6B workoutProfile runtime', () {
    const planner = BuildOnboardingFlowUseCase();

    test('mode matrix activates only canonical workoutProfile branches', () {
      final workout = planner(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.workout,
      );
      expect(workout.stepIds, contains(OnboardingStepId.workoutProfile));
      expect(
        workout.definitionFor(OnboardingStepId.workoutProfile).section,
        OnboardingSectionId.workoutProfile,
      );
      expect(workout.stepIds, isNot(contains(OnboardingStepId.workoutTargets)));

      final nutrition = planner(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.nutrition,
      );
      expect(nutrition.stepIds, isNot(contains(OnboardingStepId.workoutProfile)));

      final hybridNow = planner(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.setupNow,
      );
      expect(
        hybridNow.stepIds.indexOf(OnboardingStepId.workoutProfile),
        hybridNow.stepIds.indexOf(OnboardingStepId.workoutIntro) + 1,
      );

      final hybridLater = planner(
        entryPath: OnboardingEntryPath.firstRun,
        mode: AppMode.hybrid,
        workoutIntroChoice: WorkoutIntroChoice.later,
      );
      expect(
        hybridLater.stepIds,
        isNot(contains(OnboardingStepId.workoutProfile)),
      );
    });

    test('legacy durable workoutPreferences resumes losslessly as workoutProfile',
        () {
      const mapper = OnboardingDraftSnapshotDtoMapper();
      final snapshot = mapper.fromJson({
        'schema_version': OnboardingDraft.currentSchemaVersion,
        'status': 'inProgress',
        'selected_mode': 'workout',
        'current_step_id': 'workoutPreferences',
        'completed_step_ids': ['wellnessGoals', 'workoutPreferences'],
        'workout': {
          'current_step_id': 'trainingDays',
          'gym_access': 'home',
          'equipment': ['mat'],
          'focus_areas': ['legs'],
          'training_days': ['monday'],
          'health_concerns': '',
          'special_event': 'Local race',
        },
        'updated_at': '2026-08-22T00:00:00Z',
      });

      expect(snapshot.draft.currentStepId, OnboardingStepId.workoutProfile);
      expect(
        snapshot.draft.completedStepIds,
        contains(OnboardingStepId.workoutProfile),
      );
      expect(
        snapshot.draft.workout.currentStepId,
        WorkoutStepId.trainingDays,
      );
      expect(snapshot.draft.workout.gymAccess, WorkoutGymAccess.home);
      expect(snapshot.draft.workout.equipment, {WorkoutEquipment.mat});
      expect(snapshot.draft.workout.specialEvent, 'Local race');

      final encoded = mapper.toJson(snapshot);
      expect(encoded['current_step_id'], 'workoutProfile');
      expect(
        encoded['completed_step_ids'],
        contains('workoutProfile'),
      );
      expect(
        encoded['completed_step_ids'],
        isNot(contains('workoutPreferences')),
      );
    });

    test('O6B preserves the existing Workout child order', () {
      const builder = BuildWorkoutFlowPlanUseCase();
      expect(
        builder(gymAccess: WorkoutGymAccess.home).steps,
        const [
          WorkoutStepId.gymAccess,
          WorkoutStepId.equipment,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
          WorkoutStepId.workoutSplit,
          WorkoutStepId.healthConcerns,
          WorkoutStepId.specialEvent,
        ],
      );
    });

    test('Hybrid later removes workoutProfile without clearing Workout draft', () {
      const workoutDraft = WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.trainingDays,
        gymAccess: WorkoutGymAccess.home,
        equipment: {WorkoutEquipment.mat},
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
        specialEvent: 'Local race',
      );
      final controller = OnboardingController(
        entryPath: OnboardingEntryPath.firstRun,
        initialDraft: OnboardingDraft(
          selectedMode: AppMode.hybrid,
          workoutIntroChoice: WorkoutIntroChoice.setupNow,
          currentStepId: OnboardingStepId.workoutIntro,
          workout: workoutDraft,
        ),
      );
      addTearDown(controller.dispose);

      controller.selectWorkoutIntroChoice(WorkoutIntroChoice.later);

      expect(
        controller.state.flowPlan.stepIds,
        isNot(contains(OnboardingStepId.workoutProfile)),
      );
      expect(controller.state.draft.workout, workoutDraft);
    });
  });
}

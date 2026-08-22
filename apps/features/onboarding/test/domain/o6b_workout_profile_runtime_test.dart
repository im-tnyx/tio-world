import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_shared/shared.dart';

void main() {
  group('O6B workoutProfile compatibility after O6C', () {
    test('historical workoutPreferences with Profile child stays workoutProfile',
        () {
      const mapper = OnboardingDraftSnapshotDtoMapper();
      final snapshot = mapper.fromJson({
        'schema_version': 5,
        'status': 'inProgress',
        'selected_mode': 'workout',
        'current_step_id': 'workoutPreferences',
        'completed_step_ids': ['wellnessGoals', 'workoutPreferences'],
        'workout': {
          'current_step_id': 'focusAreas',
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
        containsAll(<OnboardingStepId>[
          OnboardingStepId.workoutProfile,
          OnboardingStepId.workoutTargets,
        ]),
      );
      expect(snapshot.draft.workout.currentStepId, WorkoutStepId.focusAreas);
      expect(snapshot.draft.workout.gymAccess, WorkoutGymAccess.home);
      expect(snapshot.draft.workout.equipment, {WorkoutEquipment.mat});
      expect(snapshot.draft.workout.specialEvent, 'Local race');

      final encoded = mapper.toJson(snapshot);
      expect(encoded['current_step_id'], 'workoutProfile');
      expect(
        encoded['completed_step_ids'],
        isNot(contains('workoutPreferences')),
      );
    });

    test('Hybrid later removes both Workout sections without clearing draft', () {
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
      expect(
        controller.state.flowPlan.stepIds,
        isNot(contains(OnboardingStepId.workoutTargets)),
      );
      expect(controller.state.draft.workout, workoutDraft);
    });
  });
}

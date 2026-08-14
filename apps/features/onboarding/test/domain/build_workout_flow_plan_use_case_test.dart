import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const useCase = BuildWorkoutFlowPlanUseCase();

  test('null and gym access both use the non-equipment initial plan', () {
    expect(useCase().steps, _gymPath);
    expect(useCase(gymAccess: WorkoutGymAccess.gym).steps, _gymPath);
    expect(useCase().stepCount, 8);
  });

  test('home access inserts equipment and expands the child plan to 9', () {
    final plan = useCase(gymAccess: WorkoutGymAccess.home);

    expect(plan.steps, _homePath);
    expect(plan.stepCount, 9);
  });

  test('reconcile keeps valid current step and safely falls back when removed',
      () {
    const homePlan = WorkoutFlowPlan(steps: _homePath);
    const gymPlan = WorkoutFlowPlan(steps: _gymPath);

    expect(
      useCase.reconcileCurrentStep(
        currentStepId: WorkoutStepId.focusAreas,
        previousPlan: homePlan,
        nextPlan: gymPlan,
      ),
      WorkoutStepId.focusAreas,
    );

    expect(
      useCase.reconcileCurrentStep(
        currentStepId: WorkoutStepId.equipment,
        previousPlan: homePlan,
        nextPlan: gymPlan,
      ),
      WorkoutStepId.gymAccess,
    );

    expect(
      useCase.reconcileCurrentStep(
        currentStepId: WorkoutStepId.experienceLevel,
        previousPlan: gymPlan,
        nextPlan: homePlan,
      ),
      WorkoutStepId.experienceLevel,
    );
  });
}

const _gymPath = [
  WorkoutStepId.gymAccess,
  WorkoutStepId.experienceLevel,
  WorkoutStepId.focusAreas,
  WorkoutStepId.trainingDays,
  WorkoutStepId.workoutDuration,
  WorkoutStepId.workoutSplit,
  WorkoutStepId.healthConcerns,
  WorkoutStepId.specialEvent,
];

const _homePath = [
  WorkoutStepId.gymAccess,
  WorkoutStepId.equipment,
  WorkoutStepId.experienceLevel,
  WorkoutStepId.focusAreas,
  WorkoutStepId.trainingDays,
  WorkoutStepId.workoutDuration,
  WorkoutStepId.workoutSplit,
  WorkoutStepId.healthConcerns,
  WorkoutStepId.specialEvent,
];

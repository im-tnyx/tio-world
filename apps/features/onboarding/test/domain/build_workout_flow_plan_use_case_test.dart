import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const useCase = BuildWorkoutFlowPlanUseCase();

  test('null and gym access both use the non-equipment initial plan', () {
    final plan = useCase();
    expect(plan.steps, _gymPath);
    expect(useCase(gymAccess: WorkoutGymAccess.gym).steps, _gymPath);
    expect(plan.stepCount, 8);
    expect(plan.profileSteps, _gymProfilePath);
    expect(plan.targetSteps, _targetPath);
  });

  test('home access inserts equipment and expands only Workout Profile', () {
    final plan = useCase(gymAccess: WorkoutGymAccess.home);

    expect(plan.steps, _homePath);
    expect(plan.stepCount, 9);
    expect(plan.profileSteps, _homeProfilePath);
    expect(plan.targetSteps, _targetPath);
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
        currentStepId: WorkoutStepId.trainingDays,
        previousPlan: gymPlan,
        nextPlan: homePlan,
      ),
      WorkoutStepId.trainingDays,
    );
  });
}

const _gymProfilePath = [
  WorkoutStepId.gymAccess,
  WorkoutStepId.experienceLevel,
  WorkoutStepId.focusAreas,
  WorkoutStepId.healthConcerns,
];

const _homeProfilePath = [
  WorkoutStepId.gymAccess,
  WorkoutStepId.equipment,
  WorkoutStepId.experienceLevel,
  WorkoutStepId.focusAreas,
  WorkoutStepId.healthConcerns,
];

const _targetPath = [
  WorkoutStepId.trainingDays,
  WorkoutStepId.workoutDuration,
  WorkoutStepId.workoutSplit,
  WorkoutStepId.specialEvent,
];

const _gymPath = [
  ..._gymProfilePath,
  ..._targetPath,
];

const _homePath = [
  ..._homeProfilePath,
  ..._targetPath,
];

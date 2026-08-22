import '../models/models.dart';

class BuildWorkoutFlowPlanUseCase {
  const BuildWorkoutFlowPlanUseCase();

  WorkoutFlowPlan call({
    WorkoutGymAccess? gymAccess,
  }) {
    return WorkoutFlowPlan(
      steps: gymAccess == WorkoutGymAccess.home
          ? const [
              WorkoutStepId.gymAccess,
              WorkoutStepId.equipment,
              WorkoutStepId.experienceLevel,
              WorkoutStepId.focusAreas,
              WorkoutStepId.healthConcerns,
              WorkoutStepId.trainingDays,
              WorkoutStepId.workoutDuration,
              WorkoutStepId.workoutSplit,
              WorkoutStepId.specialEvent,
            ]
          : const [
              WorkoutStepId.gymAccess,
              WorkoutStepId.experienceLevel,
              WorkoutStepId.focusAreas,
              WorkoutStepId.healthConcerns,
              WorkoutStepId.trainingDays,
              WorkoutStepId.workoutDuration,
              WorkoutStepId.workoutSplit,
              WorkoutStepId.specialEvent,
            ],
    );
  }

  WorkoutStepId reconcileCurrentStep({
    required WorkoutStepId currentStepId,
    required WorkoutFlowPlan previousPlan,
    required WorkoutFlowPlan nextPlan,
  }) {
    if (nextPlan.contains(currentStepId)) return currentStepId;

    final previousIndex = previousPlan.indexOf(currentStepId);
    for (var index = previousIndex - 1; index >= 0; index--) {
      final candidate = previousPlan.steps[index];
      if (nextPlan.contains(candidate)) return candidate;
    }

    return nextPlan.steps.first;
  }
}

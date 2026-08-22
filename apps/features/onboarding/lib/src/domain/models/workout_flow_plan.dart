import 'onboarding_step_id.dart';
import 'workout_step_id.dart';

class WorkoutFlowPlan {
  const WorkoutFlowPlan({
    required this.steps,
  });

  static const profileOwnedStepIds = <WorkoutStepId>{
    WorkoutStepId.gymAccess,
    WorkoutStepId.equipment,
    WorkoutStepId.experienceLevel,
    WorkoutStepId.focusAreas,
    WorkoutStepId.healthConcerns,
  };

  static const targetsOwnedStepIds = <WorkoutStepId>{
    WorkoutStepId.trainingDays,
    WorkoutStepId.workoutDuration,
    WorkoutStepId.workoutSplit,
    WorkoutStepId.specialEvent,
  };

  final List<WorkoutStepId> steps;

  int get stepCount => steps.length;

  List<WorkoutStepId> get profileSteps => List.unmodifiable(
        steps.where(profileOwnedStepIds.contains),
      );

  List<WorkoutStepId> get targetSteps => List.unmodifiable(
        steps.where(targetsOwnedStepIds.contains),
      );

  List<WorkoutStepId> stepsFor(OnboardingStepId stepId) => switch (stepId) {
        OnboardingStepId.workoutProfile => profileSteps,
        OnboardingStepId.workoutTargets => targetSteps,
        _ => const <WorkoutStepId>[],
      };

  bool contains(WorkoutStepId stepId) => steps.contains(stepId);

  int indexOf(WorkoutStepId stepId) => steps.indexOf(stepId);
}

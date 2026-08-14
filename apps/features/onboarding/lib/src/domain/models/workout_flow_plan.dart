import 'workout_step_id.dart';

class WorkoutFlowPlan {
  const WorkoutFlowPlan({
    required this.steps,
  });

  final List<WorkoutStepId> steps;

  int get stepCount => steps.length;

  bool contains(WorkoutStepId stepId) => steps.contains(stepId);

  int indexOf(WorkoutStepId stepId) => steps.indexOf(stepId);
}

import '../models/models.dart';

class WorkoutStepValidator {
  const WorkoutStepValidator();

  bool hasRequiredSelections({
    required WorkoutOnboardingDraft draft,
    required WorkoutFlowPlan flowPlan,
  }) {
    return _requiredStepIds(flowPlan).every(
      (stepId) =>
          !_validateStep(stepId: stepId, draft: draft).containsKey(stepId),
    );
  }

  Map<WorkoutStepId, String> validate({
    required WorkoutOnboardingDraft draft,
    required WorkoutFlowPlan flowPlan,
  }) {
    final currentStepId = flowPlan.contains(draft.currentStepId)
        ? draft.currentStepId
        : flowPlan.steps.first;

    return _validateStep(
      stepId: currentStepId,
      draft: draft,
    );
  }

  Map<WorkoutStepId, String> _validateStep({
    required WorkoutStepId stepId,
    required WorkoutOnboardingDraft draft,
  }) {
    return switch (stepId) {
      WorkoutStepId.gymAccess => draft.gymAccess == null
          ? const {
              WorkoutStepId.gymAccess:
                  'Choose whether you train at the gym or at home.',
            }
          : const {},
      WorkoutStepId.equipment => draft.gymAccess == WorkoutGymAccess.home &&
              draft.equipment.isEmpty
          ? const {
              WorkoutStepId.equipment: 'Select at least one equipment option.',
            }
          : const {},
      WorkoutStepId.experienceLevel => draft.experienceLevel == null
          ? const {
              WorkoutStepId.experienceLevel:
                  'Choose your current experience level.',
            }
          : const {},
      WorkoutStepId.focusAreas => draft.focusAreas.isEmpty
          ? const {
              WorkoutStepId.focusAreas: 'Select at least one focus area.',
            }
          : const {},
      WorkoutStepId.trainingDays => draft.trainingDays.isEmpty
          ? const {
              WorkoutStepId.trainingDays: 'Select at least one training day.',
            }
          : const {},
      WorkoutStepId.workoutDuration => draft.workoutDuration == null
          ? const {
              WorkoutStepId.workoutDuration: 'Choose your workout duration.',
            }
          : const {},
      WorkoutStepId.workoutSplit => draft.workoutSplit == null
          ? const {
              WorkoutStepId.workoutSplit:
                  'Choose your preferred workout split.',
            }
          : const {},
      WorkoutStepId.healthConcerns || WorkoutStepId.specialEvent => const {},
    };
  }

  Set<WorkoutStepId> _requiredStepIds(WorkoutFlowPlan flowPlan) =>
      flowPlan.steps
          .where(
            (stepId) =>
                stepId != WorkoutStepId.healthConcerns &&
                stepId != WorkoutStepId.specialEvent,
          )
          .toSet();
}

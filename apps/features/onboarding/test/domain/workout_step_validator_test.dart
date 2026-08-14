import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';

void main() {
  const validator = WorkoutStepValidator();

  test('gym access is required on the first step', () {
    final errors = validator.validate(
      draft: const WorkoutOnboardingDraft(),
      flowPlan: const WorkoutFlowPlan(
        steps: [WorkoutStepId.gymAccess],
      ),
    );

    expect(errors, contains(WorkoutStepId.gymAccess));
  });

  test('equipment is required only when home path makes it eligible', () {
    final homeErrors = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.equipment,
        gymAccess: WorkoutGymAccess.home,
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.equipment,
        ],
      ),
    );
    expect(homeErrors, contains(WorkoutStepId.equipment));

    final eligible = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.equipment,
        gymAccess: WorkoutGymAccess.home,
        equipment: {WorkoutEquipment.dumbbells},
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.equipment,
        ],
      ),
    );
    expect(eligible, isEmpty);

    final ineligible = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.experienceLevel,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
        ],
      ),
    );
    expect(ineligible, isEmpty);
  });

  test('experience level and focus areas are both required in W1', () {
    final experienceErrors = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.experienceLevel,
        gymAccess: WorkoutGymAccess.gym,
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
        ],
      ),
    );
    expect(experienceErrors, contains(WorkoutStepId.experienceLevel));

    final focusErrors = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.focusAreas,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
        ],
      ),
    );
    expect(focusErrors, contains(WorkoutStepId.focusAreas));

    final valid = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.focusAreas,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
        ],
      ),
    );
    expect(valid, isEmpty);
  });

  test('training days, duration, and split are all required in W2', () {
    final trainingErrors = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.trainingDays,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
        ],
      ),
    );
    expect(trainingErrors, contains(WorkoutStepId.trainingDays));

    final durationErrors = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.workoutDuration,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
        ],
      ),
    );
    expect(durationErrors, contains(WorkoutStepId.workoutDuration));

    final splitErrors = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.workoutSplit,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
          WorkoutStepId.workoutSplit,
        ],
      ),
    );
    expect(splitErrors, contains(WorkoutStepId.workoutSplit));

    for (final duration in WorkoutDuration.values) {
      final valid = validator.validate(
        draft: WorkoutOnboardingDraft(
          currentStepId: WorkoutStepId.workoutSplit,
          gymAccess: WorkoutGymAccess.gym,
          experienceLevel: WorkoutExperienceLevel.beginner,
          focusAreas: const {WorkoutFocusArea.legs},
          trainingDays: const {WorkoutTrainingDay.monday},
          workoutDuration: duration,
          workoutSplit: WorkoutSplit.auto,
        ),
        flowPlan: const WorkoutFlowPlan(
          steps: [
            WorkoutStepId.gymAccess,
            WorkoutStepId.experienceLevel,
            WorkoutStepId.focusAreas,
            WorkoutStepId.trainingDays,
            WorkoutStepId.workoutDuration,
            WorkoutStepId.workoutSplit,
          ],
        ),
      );
      expect(valid, isEmpty, reason: duration.name);
    }

    for (final split in WorkoutSplit.values) {
      final valid = validator.validate(
        draft: WorkoutOnboardingDraft(
          currentStepId: WorkoutStepId.workoutSplit,
          gymAccess: WorkoutGymAccess.gym,
          experienceLevel: WorkoutExperienceLevel.beginner,
          focusAreas: const {WorkoutFocusArea.legs},
          trainingDays: const {WorkoutTrainingDay.monday},
          workoutDuration: WorkoutDuration.sixtyMinutes,
          workoutSplit: split,
        ),
        flowPlan: const WorkoutFlowPlan(
          steps: [
            WorkoutStepId.gymAccess,
            WorkoutStepId.experienceLevel,
            WorkoutStepId.focusAreas,
            WorkoutStepId.trainingDays,
            WorkoutStepId.workoutDuration,
            WorkoutStepId.workoutSplit,
          ],
        ),
      );
      expect(valid, isEmpty, reason: split.name);
    }
  });

  test('required workout readiness ignores optional W3 compatibility steps',
      () {
    final ready = validator.hasRequiredSelections(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.workoutSplit,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.auto,
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
          WorkoutStepId.workoutSplit,
          WorkoutStepId.healthConcerns,
          WorkoutStepId.specialEvent,
        ],
      ),
    );

    expect(ready, isTrue);
  });

  test('health concerns and special event stay optional in W3', () {
    final healthErrors = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.healthConcerns,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.auto,
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
          WorkoutStepId.workoutSplit,
          WorkoutStepId.healthConcerns,
        ],
      ),
    );
    expect(healthErrors, isEmpty);

    final eventErrors = validator.validate(
      draft: const WorkoutOnboardingDraft(
        currentStepId: WorkoutStepId.specialEvent,
        gymAccess: WorkoutGymAccess.gym,
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.auto,
      ),
      flowPlan: const WorkoutFlowPlan(
        steps: [
          WorkoutStepId.gymAccess,
          WorkoutStepId.experienceLevel,
          WorkoutStepId.focusAreas,
          WorkoutStepId.trainingDays,
          WorkoutStepId.workoutDuration,
          WorkoutStepId.workoutSplit,
          WorkoutStepId.healthConcerns,
          WorkoutStepId.specialEvent,
        ],
      ),
    );
    expect(eventErrors, isEmpty);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/src/domain/domain.dart';
import 'package:tio_feature_workout/workout.dart' as workout_owner;

void main() {
  const mapper = WorkoutPreferencesMapper();

  group('WorkoutPreferencesMapper', () {
    test('maps valid WorkoutOnboardingDraft to canonical WorkoutPreferencesData', () {
      const draft = WorkoutOnboardingDraft(
        gymAccess: WorkoutGymAccess.home,
        equipment: {
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.bands,
        },
        experienceLevel: WorkoutExperienceLevel.advanced,
        focusAreas: {WorkoutFocusArea.chest, WorkoutFocusArea.abs},
        trainingDays: {
          WorkoutTrainingDay.tuesday,
          WorkoutTrainingDay.thursday,
          WorkoutTrainingDay.saturday,
        },
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.upperLower,
        healthConcerns: '  Previous shoulder impingement  ',
        specialEvent: '  Wedding in December  ',
      );

      final result = mapper.map(draft);

      expect(result.gymAccess, workout_owner.WorkoutGymAccess.home);
      expect(result.equipment, {
        workout_owner.WorkoutEquipment.dumbbells,
        workout_owner.WorkoutEquipment.bands,
      });
      expect(result.experienceLevel,
          workout_owner.WorkoutExperienceLevel.advanced);
      expect(result.focusAreas, {
        workout_owner.WorkoutFocusArea.chest,
        workout_owner.WorkoutFocusArea.abs,
      });
      expect(result.trainingDays, {
        workout_owner.WorkoutTrainingDay.tuesday,
        workout_owner.WorkoutTrainingDay.thursday,
        workout_owner.WorkoutTrainingDay.saturday,
      });
      expect(result.workoutDuration, workout_owner.WorkoutDuration.sixtyMinutes);
      expect(result.workoutSplit, workout_owner.WorkoutSplit.upperLower);
      expect(result.healthConcerns, 'Previous shoulder impingement');
      expect(result.specialEvent, 'Wedding in December');
    });

    test('maps safe fallback defaults when fields are null or empty', () {
      const draft = WorkoutOnboardingDraft();

      final result = mapper.map(draft);

      expect(result.gymAccess, workout_owner.WorkoutGymAccess.gym);
      expect(result.experienceLevel, workout_owner.WorkoutExperienceLevel.beginner);
      expect(result.focusAreas, {workout_owner.WorkoutFocusArea.fullBody});
      expect(result.trainingDays, {
        workout_owner.WorkoutTrainingDay.monday,
        workout_owner.WorkoutTrainingDay.wednesday,
        workout_owner.WorkoutTrainingDay.friday,
      });
      expect(result.workoutDuration, workout_owner.WorkoutDuration.sixtyMinutes);
      expect(result.workoutSplit, workout_owner.WorkoutSplit.fullBody);
      expect(result.healthConcerns, isNull);
      expect(result.specialEvent, isNull);
    });
  });
}

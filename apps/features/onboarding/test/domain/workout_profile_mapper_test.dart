import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_onboarding/onboarding.dart';
import 'package:tio_feature_workout/workout.dart' as workout_owner;

void main() {
  const mapper = WorkoutProfileMapper();

  test('unanswered Workout Profile fields remain null or explicitly empty', () {
    final profile = mapper.map(const WorkoutOnboardingDraft());

    expect(profile.workoutLocation, isNull);
    expect(profile.availableEquipment, isEmpty);
    expect(profile.experienceLevel, isNull);
    expect(profile.focusAreas, isEmpty);
    expect(profile.healthConcerns, isNull);
  });

  test('explicit Workout Profile answers map losslessly without target fields', () {
    final profile = mapper.map(
      const WorkoutOnboardingDraft(
        gymAccess: WorkoutGymAccess.home,
        equipment: {
          WorkoutEquipment.dumbbells,
          WorkoutEquipment.bands,
        },
        experienceLevel: WorkoutExperienceLevel.advanced,
        focusAreas: {
          WorkoutFocusArea.back,
          WorkoutFocusArea.legs,
        },
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.ninetyMinutes,
        workoutSplit: WorkoutSplit.ppl,
        healthConcerns: '  Knee stiffness  ',
        specialEvent: 'City 10K',
      ),
    );

    expect(profile.workoutLocation, workout_owner.WorkoutGymAccess.home);
    expect(
      profile.availableEquipment,
      {
        workout_owner.WorkoutEquipment.dumbbells,
        workout_owner.WorkoutEquipment.bands,
      },
    );
    expect(
      profile.experienceLevel,
      workout_owner.WorkoutExperienceLevel.advanced,
    );
    expect(
      profile.focusAreas,
      {
        workout_owner.WorkoutFocusArea.back,
        workout_owner.WorkoutFocusArea.legs,
      },
    );
    expect(profile.healthConcerns, {'Knee stiffness'});
  });

  test('blank health concern is not fabricated into canonical data', () {
    final profile = mapper.map(
      const WorkoutOnboardingDraft(healthConcerns: '   '),
    );

    expect(profile.healthConcerns, isNull);
  });
}

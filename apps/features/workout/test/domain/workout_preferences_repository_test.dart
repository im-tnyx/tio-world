import 'package:flutter_test/flutter_test.dart';
import 'package:tio_feature_workout/workout.dart';

void main() {
  group('InMemoryWorkoutPreferencesRepository', () {
    test('round trips workout preferences data', () async {
      final repository = InMemoryWorkoutPreferencesRepository();
      expect(await repository.getWorkoutPreferences(), isNull);

      const data = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {WorkoutEquipment.dumbbells, WorkoutEquipment.barbell},
        experienceLevel: WorkoutExperienceLevel.intermediate,
        focusAreas: {WorkoutFocusArea.chest, WorkoutFocusArea.back},
        trainingDays: {WorkoutTrainingDay.monday, WorkoutTrainingDay.thursday},
        workoutDuration: WorkoutDuration.sixtyMinutes,
        workoutSplit: WorkoutSplit.upperLower,
        healthConcerns: 'Lower back stiffness',
        specialEvent: 'Marathon next year',
      );

      await repository.saveWorkoutPreferences(data);
      final retrieved = await repository.getWorkoutPreferences();

      expect(retrieved, equals(data));
      expect(retrieved?.gymAccess, WorkoutGymAccess.gym);
      expect(retrieved?.healthConcerns, 'Lower back stiffness');
    });

    test('overwrites previous preferences on subsequent save', () async {
      final repository = InMemoryWorkoutPreferencesRepository();

      const first = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.home,
        equipment: {WorkoutEquipment.dumbbells},
        experienceLevel: WorkoutExperienceLevel.beginner,
        focusAreas: {WorkoutFocusArea.fullBody},
        trainingDays: {WorkoutTrainingDay.monday},
        workoutDuration: WorkoutDuration.thirtyMinutes,
        workoutSplit: WorkoutSplit.fullBody,
      );

      const second = WorkoutPreferencesData(
        gymAccess: WorkoutGymAccess.gym,
        equipment: {WorkoutEquipment.barbell},
        experienceLevel: WorkoutExperienceLevel.advanced,
        focusAreas: {WorkoutFocusArea.legs},
        trainingDays: {WorkoutTrainingDay.tuesday, WorkoutTrainingDay.friday},
        workoutDuration: WorkoutDuration.ninetyMinutes,
        workoutSplit: WorkoutSplit.ppl,
      );

      await repository.saveWorkoutPreferences(first);
      await repository.saveWorkoutPreferences(second);

      final retrieved = await repository.getWorkoutPreferences();
      expect(retrieved, equals(second));
    });
  });
}

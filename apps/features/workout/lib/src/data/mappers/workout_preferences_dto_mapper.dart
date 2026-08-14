import '../../domain/models/workout_duration.dart';
import '../../domain/models/workout_equipment.dart';
import '../../domain/models/workout_experience_level.dart';
import '../../domain/models/workout_focus_area.dart';
import '../../domain/models/workout_gym_access.dart';
import '../../domain/models/workout_preferences_data.dart';
import '../../domain/models/workout_split.dart';
import '../../domain/models/workout_training_day.dart';

/// Maps domain [WorkoutPreferencesData] into the verified Tnyx backend DTO schema.
class WorkoutPreferencesDtoMapper {
  const WorkoutPreferencesDtoMapper();

  Map<String, dynamic> toRequestPayload(WorkoutPreferencesData data) {
    final payload = <String, dynamic>{
      'gymAccess': mapGymAccess(data.gymAccess),
      'experienceLevel': mapExperienceLevel(data.experienceLevel),
      'focusAreas': data.focusAreas.map(mapFocusArea).toList(),
      'trainingDays': data.trainingDays.map(mapTrainingDay).toList(),
      'workoutDuration': mapWorkoutDuration(data.workoutDuration),
      'workoutSplit': mapWorkoutSplit(data.workoutSplit),
    };

    if (data.equipment.isNotEmpty) {
      payload['equipment'] = data.equipment.map(mapEquipment).toList();
    }

    if (data.healthConcerns != null &&
        data.healthConcerns!.trim().isNotEmpty) {
      payload['healthConcerns'] = data.healthConcerns!.trim();
    }

    if (data.specialEvent != null && data.specialEvent!.trim().isNotEmpty) {
      payload['specialEvent'] = data.specialEvent!.trim();
    }

    return payload;
  }

  static String mapGymAccess(WorkoutGymAccess access) => switch (access) {
        WorkoutGymAccess.home => 'home',
        WorkoutGymAccess.gym => 'gym',
      };

  static String mapEquipment(WorkoutEquipment equipment) =>
      switch (equipment) {
        WorkoutEquipment.dumbbells => 'dumbbells',
        WorkoutEquipment.bench => 'bench',
        WorkoutEquipment.mat => 'mat',
        WorkoutEquipment.barbell => 'barbell',
        WorkoutEquipment.bands => 'bands',
        WorkoutEquipment.kettlebell => 'kettlebell',
      };

  static String mapExperienceLevel(WorkoutExperienceLevel level) =>
      switch (level) {
        WorkoutExperienceLevel.fresh => 'fresh',
        WorkoutExperienceLevel.beginner => 'beginner',
        WorkoutExperienceLevel.intermediate => 'intermediate',
        WorkoutExperienceLevel.advanced => 'advanced',
      };

  static String mapFocusArea(WorkoutFocusArea area) => switch (area) {
        WorkoutFocusArea.fullBody => 'full_body',
        WorkoutFocusArea.shoulders => 'shoulders',
        WorkoutFocusArea.arms => 'arms',
        WorkoutFocusArea.back => 'back',
        WorkoutFocusArea.chest => 'chest',
        WorkoutFocusArea.abs => 'abs',
        WorkoutFocusArea.glutes => 'glutes',
        WorkoutFocusArea.legs => 'legs',
        WorkoutFocusArea.cardio => 'cardio',
      };

  static String mapTrainingDay(WorkoutTrainingDay day) => switch (day) {
        WorkoutTrainingDay.monday => 'monday',
        WorkoutTrainingDay.tuesday => 'tuesday',
        WorkoutTrainingDay.wednesday => 'wednesday',
        WorkoutTrainingDay.thursday => 'thursday',
        WorkoutTrainingDay.friday => 'friday',
        WorkoutTrainingDay.saturday => 'saturday',
        WorkoutTrainingDay.sunday => 'sunday',
      };

  static String mapWorkoutDuration(WorkoutDuration duration) =>
      switch (duration) {
        WorkoutDuration.auto => 'auto',
        WorkoutDuration.thirtyMinutes => '30_mins',
        WorkoutDuration.sixtyMinutes => '60_mins',
        WorkoutDuration.ninetyMinutes => '90_mins',
        WorkoutDuration.oneHundredTwentyMinutes => '120_mins',
      };

  static String mapWorkoutSplit(WorkoutSplit split) => switch (split) {
        WorkoutSplit.auto => 'auto',
        WorkoutSplit.fullBody => 'full_body',
        WorkoutSplit.upperLower => 'upper_lower',
        WorkoutSplit.ppl => 'ppl',
        WorkoutSplit.bodyPart => 'body_part',
      };
}

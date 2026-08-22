import 'workout_equipment.dart';
import 'workout_experience_level.dart';
import 'workout_focus_area.dart';
import 'workout_gym_access.dart';

/// Canonical Workout Profile context owned by `user_workout_profiles`.
///
/// Schedule, goal and plan constraints intentionally belong to the separate
/// canonical Workout Targets owner.
class WorkoutProfileData {
  const WorkoutProfileData({
    this.workoutLocation,
    this.availableEquipment,
    this.experienceLevel,
    this.focusAreas,
    this.healthConcerns,
  });

  final WorkoutGymAccess? workoutLocation;
  final Set<WorkoutEquipment>? availableEquipment;
  final WorkoutExperienceLevel? experienceLevel;
  final Set<WorkoutFocusArea>? focusAreas;
  final Set<String>? healthConcerns;
}

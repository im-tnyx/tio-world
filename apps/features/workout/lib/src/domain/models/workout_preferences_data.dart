import 'workout_duration.dart';
import 'workout_equipment.dart';
import 'workout_experience_level.dart';
import 'workout_focus_area.dart';
import 'workout_gym_access.dart';
import 'workout_split.dart';
import 'workout_training_day.dart';

/// Immutable domain model representing user workout preferences captured during setup/onboarding.
class WorkoutPreferencesData {
  const WorkoutPreferencesData({
    required this.gymAccess,
    required this.equipment,
    required this.experienceLevel,
    required this.focusAreas,
    required this.trainingDays,
    required this.workoutDuration,
    required this.workoutSplit,
    this.healthConcerns,
    this.specialEvent,
  });

  final WorkoutGymAccess gymAccess;
  final Set<WorkoutEquipment> equipment;
  final WorkoutExperienceLevel experienceLevel;
  final Set<WorkoutFocusArea> focusAreas;
  final Set<WorkoutTrainingDay> trainingDays;
  final WorkoutDuration workoutDuration;
  final WorkoutSplit workoutSplit;
  final String? healthConcerns;
  final String? specialEvent;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkoutPreferencesData &&
            runtimeType == other.runtimeType &&
            gymAccess == other.gymAccess &&
            equipment.length == other.equipment.length &&
            equipment.containsAll(other.equipment) &&
            experienceLevel == other.experienceLevel &&
            focusAreas.length == other.focusAreas.length &&
            focusAreas.containsAll(other.focusAreas) &&
            trainingDays.length == other.trainingDays.length &&
            trainingDays.containsAll(other.trainingDays) &&
            workoutDuration == other.workoutDuration &&
            workoutSplit == other.workoutSplit &&
            healthConcerns == other.healthConcerns &&
            specialEvent == other.specialEvent;
  }

  @override
  int get hashCode => Object.hash(
        gymAccess,
        Object.hashAll(equipment),
        experienceLevel,
        Object.hashAll(focusAreas),
        Object.hashAll(trainingDays),
        workoutDuration,
        workoutSplit,
        healthConcerns,
        specialEvent,
      );

  @override
  String toString() {
    // Redact sensitive free-text health concerns in default string representation
    return 'WorkoutPreferencesData(gymAccess: $gymAccess, experience: $experienceLevel, split: $workoutSplit)';
  }
}

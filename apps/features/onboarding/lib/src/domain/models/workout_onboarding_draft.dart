import 'workout_equipment.dart';
import 'workout_duration.dart';
import 'workout_experience_level.dart';
import 'workout_focus_area.dart';
import 'workout_gym_access.dart';
import 'workout_split.dart';
import 'workout_step_id.dart';
import 'workout_training_day.dart';

class WorkoutOnboardingDraft {
  const WorkoutOnboardingDraft({
    this.currentStepId = WorkoutStepId.gymAccess,
    this.gymAccess,
    this.equipment = const <WorkoutEquipment>{},
    this.experienceLevel,
    this.focusAreas = const <WorkoutFocusArea>{},
    this.trainingDays = const <WorkoutTrainingDay>{},
    this.workoutDuration,
    this.workoutSplit,
    this.healthConcerns = '',
    this.specialEvent = '',
  });

  final WorkoutStepId currentStepId;
  final WorkoutGymAccess? gymAccess;
  final Set<WorkoutEquipment> equipment;
  final WorkoutExperienceLevel? experienceLevel;
  final Set<WorkoutFocusArea> focusAreas;
  final Set<WorkoutTrainingDay> trainingDays;
  final WorkoutDuration? workoutDuration;
  final WorkoutSplit? workoutSplit;
  final String healthConcerns;
  final String specialEvent;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is WorkoutOnboardingDraft &&
            currentStepId == other.currentStepId &&
            gymAccess == other.gymAccess &&
            experienceLevel == other.experienceLevel &&
            workoutDuration == other.workoutDuration &&
            workoutSplit == other.workoutSplit &&
            healthConcerns == other.healthConcerns &&
            specialEvent == other.specialEvent &&
            equipment.length == other.equipment.length &&
            equipment.every(other.equipment.contains) &&
            focusAreas.length == other.focusAreas.length &&
            focusAreas.every(other.focusAreas.contains) &&
            trainingDays.length == other.trainingDays.length &&
            trainingDays.every(other.trainingDays.contains);
  }

  @override
  int get hashCode => Object.hash(
        currentStepId,
        gymAccess,
        experienceLevel,
        workoutDuration,
        workoutSplit,
        healthConcerns,
        specialEvent,
        Object.hashAllUnordered(equipment),
        Object.hashAllUnordered(focusAreas),
        Object.hashAllUnordered(trainingDays),
      );

  WorkoutOnboardingDraft copyWith({
    WorkoutStepId? currentStepId,
    WorkoutGymAccess? gymAccess,
    bool clearGymAccess = false,
    Set<WorkoutEquipment>? equipment,
    WorkoutExperienceLevel? experienceLevel,
    bool clearExperienceLevel = false,
    Set<WorkoutFocusArea>? focusAreas,
    Set<WorkoutTrainingDay>? trainingDays,
    WorkoutDuration? workoutDuration,
    bool clearWorkoutDuration = false,
    WorkoutSplit? workoutSplit,
    bool clearWorkoutSplit = false,
    String? healthConcerns,
    String? specialEvent,
  }) {
    return WorkoutOnboardingDraft(
      currentStepId: currentStepId ?? this.currentStepId,
      gymAccess: clearGymAccess ? null : gymAccess ?? this.gymAccess,
      equipment: equipment ?? this.equipment,
      experienceLevel:
          clearExperienceLevel ? null : experienceLevel ?? this.experienceLevel,
      focusAreas: focusAreas ?? this.focusAreas,
      trainingDays: trainingDays ?? this.trainingDays,
      workoutDuration:
          clearWorkoutDuration ? null : workoutDuration ?? this.workoutDuration,
      workoutSplit:
          clearWorkoutSplit ? null : workoutSplit ?? this.workoutSplit,
      healthConcerns: healthConcerns ?? this.healthConcerns,
      specialEvent: specialEvent ?? this.specialEvent,
    );
  }
}

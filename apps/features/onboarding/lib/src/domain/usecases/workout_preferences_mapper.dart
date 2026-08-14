import 'package:tio_feature_workout/workout.dart' as workout_owner;

import '../models/models.dart';

/// Pure mapper from onboarding [WorkoutOnboardingDraft] to canonical [workout_owner.WorkoutPreferencesData].
class WorkoutPreferencesMapper {
  const WorkoutPreferencesMapper();

  workout_owner.WorkoutPreferencesData map(WorkoutOnboardingDraft draft) {
    final gymAccess = draft.gymAccess;
    if (gymAccess == null) {
      throw const FormatException(
          'Workout preferences setup requires a gym access choice.');
    }

    final experience = draft.experienceLevel;
    if (experience == null) {
      throw const FormatException(
          'Workout preferences setup requires an experience level.');
    }

    if (draft.focusAreas.isEmpty) {
      throw const FormatException(
          'Workout preferences setup requires at least one focus area.');
    }

    if (draft.trainingDays.isEmpty) {
      throw const FormatException(
          'Workout preferences setup requires at least one training day.');
    }

    final duration = draft.workoutDuration;
    if (duration == null) {
      throw const FormatException(
          'Workout preferences setup requires a workout duration.');
    }

    final split = draft.workoutSplit;
    if (split == null) {
      throw const FormatException(
          'Workout preferences setup requires a workout split program.');
    }

    return workout_owner.WorkoutPreferencesData(
      gymAccess: switch (gymAccess) {
        WorkoutGymAccess.gym => workout_owner.WorkoutGymAccess.gym,
        WorkoutGymAccess.home => workout_owner.WorkoutGymAccess.home,
      },
      equipment: draft.equipment
          .map((eq) => switch (eq) {
                WorkoutEquipment.dumbbells =>
                  workout_owner.WorkoutEquipment.dumbbells,
                WorkoutEquipment.bench => workout_owner.WorkoutEquipment.bench,
                WorkoutEquipment.mat => workout_owner.WorkoutEquipment.mat,
                WorkoutEquipment.barbell =>
                  workout_owner.WorkoutEquipment.barbell,
                WorkoutEquipment.bands => workout_owner.WorkoutEquipment.bands,
                WorkoutEquipment.kettlebell =>
                  workout_owner.WorkoutEquipment.kettlebell,
              })
          .toSet(),
      experienceLevel: switch (experience) {
        WorkoutExperienceLevel.fresh =>
          workout_owner.WorkoutExperienceLevel.fresh,
        WorkoutExperienceLevel.beginner =>
          workout_owner.WorkoutExperienceLevel.beginner,
        WorkoutExperienceLevel.intermediate =>
          workout_owner.WorkoutExperienceLevel.intermediate,
        WorkoutExperienceLevel.advanced =>
          workout_owner.WorkoutExperienceLevel.advanced,
      },
      focusAreas: draft.focusAreas
          .map((fa) => switch (fa) {
                WorkoutFocusArea.fullBody =>
                  workout_owner.WorkoutFocusArea.fullBody,
                WorkoutFocusArea.shoulders =>
                  workout_owner.WorkoutFocusArea.shoulders,
                WorkoutFocusArea.arms => workout_owner.WorkoutFocusArea.arms,
                WorkoutFocusArea.back => workout_owner.WorkoutFocusArea.back,
                WorkoutFocusArea.chest => workout_owner.WorkoutFocusArea.chest,
                WorkoutFocusArea.abs => workout_owner.WorkoutFocusArea.abs,
                WorkoutFocusArea.glutes => workout_owner.WorkoutFocusArea.glutes,
                WorkoutFocusArea.legs => workout_owner.WorkoutFocusArea.legs,
                WorkoutFocusArea.cardio => workout_owner.WorkoutFocusArea.cardio,
              })
          .toSet(),
      trainingDays: draft.trainingDays
          .map((td) => switch (td) {
                WorkoutTrainingDay.monday =>
                  workout_owner.WorkoutTrainingDay.monday,
                WorkoutTrainingDay.tuesday =>
                  workout_owner.WorkoutTrainingDay.tuesday,
                WorkoutTrainingDay.wednesday =>
                  workout_owner.WorkoutTrainingDay.wednesday,
                WorkoutTrainingDay.thursday =>
                  workout_owner.WorkoutTrainingDay.thursday,
                WorkoutTrainingDay.friday =>
                  workout_owner.WorkoutTrainingDay.friday,
                WorkoutTrainingDay.saturday =>
                  workout_owner.WorkoutTrainingDay.saturday,
                WorkoutTrainingDay.sunday =>
                  workout_owner.WorkoutTrainingDay.sunday,
              })
          .toSet(),
      workoutDuration: switch (duration) {
        WorkoutDuration.auto => workout_owner.WorkoutDuration.auto,
        WorkoutDuration.thirtyMinutes =>
          workout_owner.WorkoutDuration.thirtyMinutes,
        WorkoutDuration.sixtyMinutes =>
          workout_owner.WorkoutDuration.sixtyMinutes,
        WorkoutDuration.ninetyMinutes =>
          workout_owner.WorkoutDuration.ninetyMinutes,
        WorkoutDuration.oneHundredTwentyMinutes =>
          workout_owner.WorkoutDuration.oneHundredTwentyMinutes,
      },
      workoutSplit: switch (split) {
        WorkoutSplit.auto => workout_owner.WorkoutSplit.auto,
        WorkoutSplit.fullBody => workout_owner.WorkoutSplit.fullBody,
        WorkoutSplit.upperLower => workout_owner.WorkoutSplit.upperLower,
        WorkoutSplit.ppl => workout_owner.WorkoutSplit.ppl,
        WorkoutSplit.bodyPart => workout_owner.WorkoutSplit.bodyPart,
      },
      healthConcerns: draft.healthConcerns.trim().isEmpty
          ? null
          : draft.healthConcerns.trim(),
      specialEvent: draft.specialEvent.trim().isEmpty
          ? null
          : draft.specialEvent.trim(),
    );
  }
}

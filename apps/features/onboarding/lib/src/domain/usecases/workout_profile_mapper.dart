import 'package:tio_feature_workout/workout.dart' as workout_owner;

import '../models/models.dart';

/// Strict owner mapper from Product Onboarding Workout Profile answers to the
/// canonical `user_workout_profiles` domain contract.
///
/// Unlike the legacy broad Workout preferences mapper, this mapper never
/// invents fallback answers for missing onboarding state.
class WorkoutProfileMapper {
  const WorkoutProfileMapper();

  workout_owner.WorkoutProfileData map(WorkoutOnboardingDraft draft) {
    final healthConcern = draft.healthConcerns.trim();

    return workout_owner.WorkoutProfileData(
      workoutLocation: switch (draft.gymAccess) {
        WorkoutGymAccess.gym => workout_owner.WorkoutGymAccess.gym,
        WorkoutGymAccess.home => workout_owner.WorkoutGymAccess.home,
        null => null,
      },
      availableEquipment: draft.equipment
          .map((equipment) => switch (equipment) {
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
      experienceLevel: switch (draft.experienceLevel) {
        WorkoutExperienceLevel.fresh =>
          workout_owner.WorkoutExperienceLevel.fresh,
        WorkoutExperienceLevel.beginner =>
          workout_owner.WorkoutExperienceLevel.beginner,
        WorkoutExperienceLevel.intermediate =>
          workout_owner.WorkoutExperienceLevel.intermediate,
        WorkoutExperienceLevel.advanced =>
          workout_owner.WorkoutExperienceLevel.advanced,
        null => null,
      },
      focusAreas: draft.focusAreas
          .map((focusArea) => switch (focusArea) {
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
      healthConcerns: healthConcern.isEmpty ? null : {healthConcern},
    );
  }
}

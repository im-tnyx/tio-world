import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/workout/equipment_screen.dart';
import '../screens/workout/experience_level_screen.dart';
import '../screens/workout/focus_areas_screen.dart';
import '../screens/workout/gym_access_screen.dart';
import '../screens/workout/health_concerns_screen.dart';
import '../screens/workout/special_event_screen.dart';
import '../screens/workout/training_days_screen.dart';
import '../screens/workout/workout_duration_screen.dart';
import '../screens/workout/workout_split_screen.dart';
import '../state/state.dart';

class WorkoutStepRenderer extends StatelessWidget {
  const WorkoutStepRenderer({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final draft = state.draft.workout;
    final errorText = state.validationErrors[draft.currentStepId.name];

    return switch (draft.currentStepId) {
      WorkoutStepId.gymAccess => GymAccessScreen(
          selectedAccess: draft.gymAccess,
          flowPlan: state.workoutFlowPlan,
          onSelected: controller.updateGymAccess,
          errorText: errorText,
        ),
      WorkoutStepId.equipment => EquipmentScreen(
          selectedEquipment: draft.equipment,
          flowPlan: state.workoutFlowPlan,
          onToggled: controller.toggleEquipment,
          errorText: errorText,
        ),
      WorkoutStepId.experienceLevel => ExperienceLevelScreen(
          selectedLevel: draft.experienceLevel,
          flowPlan: state.workoutFlowPlan,
          onSelected: controller.updateExperienceLevel,
          errorText: errorText,
        ),
      WorkoutStepId.focusAreas => FocusAreasScreen(
          selectedAreas: draft.focusAreas,
          flowPlan: state.workoutFlowPlan,
          onToggled: controller.toggleFocusArea,
          errorText: errorText,
        ),
      WorkoutStepId.trainingDays => TrainingDaysScreen(
          selectedDays: draft.trainingDays,
          flowPlan: state.workoutFlowPlan,
          onToggled: controller.toggleTrainingDay,
          errorText: errorText,
        ),
      WorkoutStepId.workoutDuration => WorkoutDurationScreen(
          selectedDuration: draft.workoutDuration,
          flowPlan: state.workoutFlowPlan,
          onSelected: controller.updateWorkoutDuration,
          errorText: errorText,
        ),
      WorkoutStepId.workoutSplit => WorkoutSplitScreen(
          selectedSplit: draft.workoutSplit,
          flowPlan: state.workoutFlowPlan,
          onSelected: controller.updateWorkoutSplit,
          errorText: errorText,
        ),
      WorkoutStepId.healthConcerns => HealthConcernsScreen(
          value: draft.healthConcerns,
          flowPlan: state.workoutFlowPlan,
          onChanged: controller.updateWorkoutHealthConcerns,
          errorText: errorText,
        ),
      WorkoutStepId.specialEvent => SpecialEventScreen(
          value: draft.specialEvent,
          flowPlan: state.workoutFlowPlan,
          onChanged: controller.updateWorkoutSpecialEvent,
          errorText: errorText,
        ),
    };
  }
}

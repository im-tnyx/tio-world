import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/profile/activity_screen.dart';
import '../screens/profile/age_screen.dart';
import '../screens/profile/current_weight_screen.dart';
import '../screens/profile/gender_screen.dart';
import '../screens/profile/goal_screen.dart';
import '../screens/profile/health_conditions_screen.dart';
import '../screens/profile/height_screen.dart';
import '../screens/profile/name_screen.dart';
import '../screens/profile/target_weight_screen.dart';
import '../state/state.dart';

class ProfileStepRenderer extends StatelessWidget {
  const ProfileStepRenderer(
      {required this.state, required this.controller, super.key});

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final draft = state.draft.profile;
    final errorText = state.validationErrors[draft.currentStepId.name];

    return switch (draft.currentStepId) {
      ProfileStepId.name => NameScreen(
          value: draft.name,
          onChanged: controller.updateProfileName,
          errorText: errorText),
      ProfileStepId.gender => GenderScreen(
          selectedGender: draft.gender,
          onSelected: controller.updateProfileGender,
          errorText: errorText),
      ProfileStepId.goal => GoalScreen(
          selectedGoals: draft.goals,
          onToggled: controller.toggleProfileGoal,
          errorText: errorText),
      ProfileStepId.age => AgeScreen(
          value: draft.dateOfBirth,
          onChanged: controller.updateProfileDateOfBirth,
          errorText: errorText),
      ProfileStepId.height => HeightScreen(
          valueCm: draft.heightCm,
          onChanged: controller.updateProfileHeight,
          errorText: errorText),
      ProfileStepId.currentWeight => CurrentWeightScreen(
          valueKg: draft.currentWeightKg,
          onChanged: controller.updateProfileCurrentWeight,
          errorText: errorText),
      ProfileStepId.targetWeight => TargetWeightScreen(
          valueKg: draft.targetWeightKg,
          onChanged: controller.updateProfileTargetWeight,
          errorText: errorText),
      ProfileStepId.activity => ActivityScreen(
          selectedActivity: draft.activityLevel,
          onSelected: controller.updateProfileActivity,
          errorText: errorText),
      ProfileStepId.healthConditions => HealthConditionsScreen(
          selectedConditions: draft.healthConditions,
          otherText: draft.otherHealthCondition,
          onToggled: controller.toggleProfileHealthCondition,
          onOtherTextChanged: controller.updateOtherHealthCondition,
          errorText: errorText,
        ),
    };
  }
}

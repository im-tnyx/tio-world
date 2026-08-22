import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/goal/goal_intent_screen.dart';
import '../screens/profile/activity_screen.dart';
import '../screens/profile/age_screen.dart';
import '../screens/profile/current_weight_screen.dart';
import '../screens/profile/gender_screen.dart';
import '../screens/profile/health_conditions_screen.dart';
import '../screens/profile/height_screen.dart';
import '../screens/profile/measurement_units_screen.dart';
import '../screens/profile/name_screen.dart';
import '../screens/profile/profile_screen_components.dart';
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

    final screen = switch (draft.currentStepId) {
      ProfileStepId.name => NameScreen(
          value: draft.name,
          onChanged: controller.updateProfileName,
          errorText: errorText),
      ProfileStepId.gender => GenderScreen(
          selectedGender: draft.gender,
          onSelected: controller.updateProfileGender,
          errorText: errorText),
      ProfileStepId.goal => GoalIntentScreen(
          mode: state.draft.selectedMode!,
          selection: state.draft.goalSelection,
          onGoalTapped: controller.tapGoalIntent,
          errorText: errorText,
        ),
      ProfileStepId.age => AgeScreen(
          value: draft.dateOfBirth,
          onChanged: controller.updateProfileDateOfBirth,
          onContinue: () => controller.next(onFinish: (_) async {}),
          isBusy: state.isBusy,
          errorText: errorText),
      ProfileStepId.measurementUnits => MeasurementUnitsScreen(
          preferences: draft.unitPreferences,
          onChanged: controller.updateMeasurementUnitPreferences,
        ),
      ProfileStepId.height => HeightScreen(
          valueCm: draft.heightCm,
          unit: draft.heightUnit,
          onChanged: controller.updateProfileHeight,
          onContinue: () => controller.next(onFinish: (_) async {}),
          isBusy: state.isBusy,
          errorText: errorText),
      ProfileStepId.currentWeight => CurrentWeightScreen(
          valueKg: draft.currentWeightKg,
          unit: draft.weightUnit,
          heightCm: draft.heightCm,
          onChanged: controller.updateProfileCurrentWeight,
          onContinue: () => controller.next(onFinish: (_) async {}),
          isBusy: state.isBusy,
          errorText: errorText),
      ProfileStepId.targetWeight => TargetWeightScreen(
          valueKg: draft.targetWeightKg,
          unit: draft.weightUnit,
          currentWeightKg: draft.currentWeightKg,
          weightGoalDirection: state.weightGoalDirection,
          heightCm: draft.heightCm,
          onChanged: controller.updateProfileTargetWeight,
          onContinue: () => controller.next(onFinish: (_) async {}),
          isBusy: state.isBusy,
          errorText: errorText),
      ProfileStepId.goalPace => throw StateError(
          'Goal Pace is Body Goal-owned and cannot render in ProfileSection.',
        ),
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

    return ProfileFlowPlanScope(
      flowPlan: state.profileFlowPlan,
      child: screen,
    );
  }
}

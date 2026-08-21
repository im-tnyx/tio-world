import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/targets/bridge_screen.dart';
import '../screens/targets/goal_pace_screen.dart';
import '../screens/targets/nutrition_target_screen.dart';
import '../screens/targets/sleep_target_screen.dart';
import '../screens/targets/step_target_screen.dart';
import '../screens/targets/targets_screen_components.dart';
import '../screens/targets/water_target_screen.dart';
import '../state/state.dart';

class TargetStepRenderer extends StatelessWidget {
  const TargetStepRenderer({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final draft = state.draft.targets;
    final profile = state.draft.profile;
    final errorText = state.validationErrors[draft.currentStepId.name];

    final screen = switch (draft.currentStepId) {
      TargetStepId.bridge => BridgeScreen(errorText: errorText),
      TargetStepId.stepTarget => StepTargetScreen(
          dailySteps: draft.dailySteps,
          onChanged: controller.updateDailyStepTarget,
          errorText: errorText,
        ),
      TargetStepId.sleepTarget => SleepTargetScreen(
          sleepTargetMinutes: draft.sleepTargetMinutes,
          sleepTimeMinutes: draft.sleepTimeMinutes,
          wakeTimeMinutes: draft.wakeTimeMinutes,
          onSleepScheduleChange: controller.updateSleepSchedule,
          errorText: errorText,
        ),
      TargetStepId.waterTarget => WaterTargetScreen(
          waterMl: draft.waterMl,
          volumeUnit: profile.unitPreferences.volumeUnit,
          onVolumeUnitChanged: (volumeUnit) =>
              controller.updateMeasurementUnitPreferences(
            profile.unitPreferences.copyWith(volumeUnit: volumeUnit),
          ),
          onChanged: controller.updateWaterTargetMl,
          errorText: errorText,
        ),
      TargetStepId.goalPace => GoalPaceScreen(
          goalPaceKgPerWeek: draft.goalPaceKgPerWeek,
          onPaceChanged: controller.updateGoalPaceKgPerWeek,
          profile: profile,
          weightGoalDirection: state.weightGoalDirection!,
          stepTarget: draft.dailySteps,
          errorText: errorText,
        ),
      TargetStepId.nutritionTarget => NutritionTargetScreen(
          profile: profile,
          targets: draft,
          errorText: errorText,
        ),
    };

    return TargetsFlowPlanScope(
      flowPlan: state.targetsFlowPlan,
      child: screen,
    );
  }
}

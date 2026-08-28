import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../screens/goal/goal_intent_screen.dart';
import '../screens/profile/current_weight_screen.dart';
import '../screens/profile/profile_screen_components.dart';
import '../screens/profile/target_weight_screen.dart';
import '../screens/targets/goal_pace_screen.dart';
import '../state/state.dart';

/// Canonical Body Goal onboarding section.
///
/// It deliberately reuses the existing Goal/current/target/pace screens and
/// existing draft value containers while runtime ownership moves out of common
/// Profile and Targets navigation. Durable Body ownership remains unchanged.
class BodyGoalSection extends StatelessWidget {
  const BodyGoalSection({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.bodyGoal ||
        state.currentSection != OnboardingSectionId.bodyGoal) {
      throw StateError('BodyGoalSection can only render the Body Goal section.');
    }

    final profile = state.draft.profile;
    final stepId = profile.currentStepId;
    if (!state.bodyGoalFlowPlan.contains(stepId)) {
      throw StateError('Invalid Body Goal child step: ${stepId.name}.');
    }

    final errorText = state.validationErrors[stepId.name];
    final mode = state.draft.selectedMode;
    if (mode == null) {
      throw StateError('Body Goal requires a selected App Mode.');
    }

    void updateTargetWeight(double value) {
      // Training-only intent deliberately has no Body direction until the user
      // answers Target Weight. The first non-zero target delta makes that
      // direction explicit by selecting the matching Body weight-state card;
      // no training label, BMI or default is used to infer it.
      if (controller.state.weightGoalDirection == null) {
        final currentWeight = controller.state.draft.profile.currentWeightKg;
        if (currentWeight != null && value != currentWeight) {
          controller.tapGoalIntent(
            value < currentWeight
                ? GoalIntent.loseWeight
                : GoalIntent.gainWeight,
          );
        }
      }
      controller.updateProfileTargetWeight(value);
    }

    final screen = switch (stepId) {
      ProfileStepId.goal => GoalIntentScreen(
          mode: mode,
          selection: state.draft.goalSelection,
          onGoalTapped: controller.tapGoalIntent,
          errorText: errorText,
        ),
      ProfileStepId.currentWeight => CurrentWeightScreen(
          valueKg: profile.currentWeightKg,
          unit: profile.weightUnit,
          heightCm: profile.heightCm,
          onChanged: controller.updateProfileCurrentWeight,
          onContinue: () => controller.next(onFinish: (_) async {}),
          isBusy: state.isBusy,
          errorText: errorText,
        ),
      ProfileStepId.targetWeight => TargetWeightScreen(
          valueKg: profile.targetWeightKg,
          unit: profile.weightUnit,
          currentWeightKg: profile.currentWeightKg,
          weightGoalDirection: state.weightGoalDirection,
          heightCm: profile.heightCm,
          onChanged: updateTargetWeight,
          onContinue: () => controller.next(onFinish: (_) async {}),
          isBusy: state.isBusy,
          errorText: errorText,
        ),
      ProfileStepId.goalPace => GoalPaceScreen(
          goalPaceKgPerWeek: state.draft.targets.goalPaceKgPerWeek,
          onPaceChanged: controller.updateGoalPaceKgPerWeek,
          profile: profile,
          weightGoalDirection: state.weightGoalDirection!,
          errorText: errorText,
        ),
      _ => throw StateError('Unsupported Body Goal child step: ${stepId.name}.'),
    };

    return ProfileFlowPlanScope(
      flowPlan: ProfileFlowPlan(steps: state.bodyGoalFlowPlan.steps),
      child: screen,
    );
  }
}

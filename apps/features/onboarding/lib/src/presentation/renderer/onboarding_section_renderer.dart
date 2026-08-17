import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../controllers/controllers.dart';
import '../sections/app_mode_section.dart';
import '../sections/mobile_section.dart';
import '../sections/nutrition_intro_section.dart';
import '../sections/nutrition_section.dart';
import '../sections/profile_section.dart';
import '../sections/review_section.dart';
import '../sections/targets_section.dart';
import '../sections/workout_intro_section.dart';
import '../sections/workout_section.dart';
import '../state/state.dart';

class OnboardingSectionRenderer extends StatelessWidget {
  const OnboardingSectionRenderer({
    required this.state,
    required this.controller,
    super.key,
  });

  final OnboardingState state;
  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return switch (state.currentSection) {
      OnboardingSectionId.appMode => AppModeSection(
          state: state,
          controller: controller,
        ),
      OnboardingSectionId.profile => ProfileSection(
          state: state,
          controller: controller,
        ),
      OnboardingSectionId.mobile => MobileSection(
          state: state,
          controller: controller,
        ),
      OnboardingSectionId.workoutIntro => WorkoutIntroSection(
          state: state,
          controller: controller,
        ),
      OnboardingSectionId.workout => WorkoutSection(
          state: state,
          controller: controller,
        ),
      OnboardingSectionId.nutritionIntro => NutritionIntroSection(
          state: state,
          controller: controller,
        ),
      OnboardingSectionId.nutrition => NutritionSection(
          state: state,
          controller: controller,
        ),
      OnboardingSectionId.targets => TargetsSection(
          state: state,
          controller: controller,
        ),
      OnboardingSectionId.review => ReviewSection(state: state),
    };
  }
}

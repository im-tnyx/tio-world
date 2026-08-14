import 'package:flutter/material.dart';

import '../../domain/domain.dart';
import '../screens/compatibility/compatibility_onboarding_screen.dart';
import '../state/state.dart';

class NutritionStepRenderer extends StatelessWidget {
  const NutritionStepRenderer({
    required this.state,
    super.key,
  });

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    if (state.stepId != OnboardingStepId.nutritionPreferences) {
      throw StateError(
        'NutritionStepRenderer can only render nutritionPreferences.',
      );
    }

    return const CompatibilityOnboardingScreen(
      title: 'Nutrition preferences',
      description:
          'Nutrition owner contracts are not yet present in local Tio-World source, so onboarding keeps this boundary real but leaves the actual preference fields blocked.',
      highlights: [
        'No diet types, allergies, meal counts, or exclusions were invented here.',
        'Targets remain separate and are not calculated in NutritionPreferences.',
        'Continue remains fixed at the bottom of the parent shell.',
      ],
    );
  }
}

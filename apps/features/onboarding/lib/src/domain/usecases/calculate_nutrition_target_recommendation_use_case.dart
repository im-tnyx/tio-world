import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_domain;

import '../models/models.dart';

/// Adapter usecase in onboarding that converts onboarding draft state
/// to [nutrition_domain.NutritionTargetInputs] and executes canonical calculation via
/// [nutrition_domain.NutritionTargetCalculator].
class CalculateNutritionTargetRecommendationUseCase {
  const CalculateNutritionTargetRecommendationUseCase({
    this.calculator = const nutrition_domain.NutritionTargetCalculator(),
  });

  final nutrition_domain.NutritionTargetCalculator calculator;

  nutrition_domain.NutritionTargetRecommendationResult call({
    required ProfileOnboardingDraft profile,
    required TargetsOnboardingDraft targets,
    DateTime? now,
  }) {
    final inputs = nutrition_domain.NutritionTargetInputs(
      gender: profile.gender?.name,
      primaryGoal: profile.goals.firstOrNull?.name,
      dateOfBirth: profile.dateOfBirth,
      heightCm: profile.heightCm,
      weightKg: profile.currentWeightKg,
      activityLevel: profile.activityLevel?.name,
      goalPaceKgPerWeek: targets.goalPaceKgPerWeek,
      dailyStepTarget: targets.dailySteps,
    );

    return calculator.calculate(inputs, now: now);
  }
}

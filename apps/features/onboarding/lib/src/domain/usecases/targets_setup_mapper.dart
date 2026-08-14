import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;

import '../models/models.dart';
import 'calculate_nutrition_target_recommendation_use_case.dart';

/// Pure mapper from onboarding [TargetsOnboardingDraft] and calculated recommendation
/// to canonical [nutrition_owner.TargetsSetupData].
class TargetsSetupMapper {
  const TargetsSetupMapper({
    this.calculator = const CalculateNutritionTargetRecommendationUseCase(),
  });

  final CalculateNutritionTargetRecommendationUseCase calculator;

  nutrition_owner.TargetsSetupData map({
    required TargetsOnboardingDraft targetsDraft,
    required ProfileOnboardingDraft profileDraft,
  }) {
    if (targetsDraft.dailySteps < 2000 || targetsDraft.dailySteps > 18000) {
      throw const FormatException(
          'Daily step target out of valid bounds (2000..18000).');
    }

    if (targetsDraft.sleepTargetMinutes < 240 ||
        targetsDraft.sleepTargetMinutes > 720) {
      throw const FormatException(
          'Sleep duration target out of valid bounds (240..720 min).');
    }

    if (targetsDraft.waterMl < 1000 || targetsDraft.waterMl > 8000) {
      throw const FormatException(
          'Daily hydration target out of valid bounds (1000..8000 ml).');
    }

    final recommendationResult = calculator(
      profile: profileDraft,
      targets: targetsDraft,
    );

    final recommendation =
        recommendationResult is NutritionTargetRecommendationSuccess
            ? recommendationResult.recommendation
            : null;

    return nutrition_owner.TargetsSetupData(
      dailySteps: targetsDraft.dailySteps,
      sleepTargetMinutes: targetsDraft.sleepTargetMinutes,
      sleepTimeMinutes: targetsDraft.sleepTimeMinutes,
      wakeTimeMinutes: targetsDraft.wakeTimeMinutes,
      waterMl: targetsDraft.waterMl,
      goalPaceKgPerWeek: targetsDraft.goalPaceKgPerWeek,
      recommendation: recommendation,
    );
  }
}

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
    GoalWeightDirection? activeWeightDirection,
  }) {
    final dailySteps = targetsDraft.dailySteps.clamp(1000, 50000);
    final sleepTargetMinutes = targetsDraft.sleepTargetMinutes.clamp(180, 840);
    final waterMl = targetsDraft.waterMl.clamp(500, 15000);
    final targetIsActive = activeWeightDirection != null &&
        profileDraft.targetWeightDirection == activeWeightDirection;
    final effectiveProfile = targetIsActive
        ? profileDraft
        : profileDraft.copyWith(clearTargetWeightKg: true);

    final recommendationResult = calculator(
      profile: effectiveProfile,
      targets: targetsDraft,
    );

    final recommendation =
        recommendationResult is NutritionTargetRecommendationSuccess
            ? recommendationResult.recommendation
            : null;

    return nutrition_owner.TargetsSetupData(
      dailySteps: dailySteps,
      sleepTargetMinutes: sleepTargetMinutes,
      sleepTimeMinutes: targetsDraft.sleepTimeMinutes,
      wakeTimeMinutes: targetsDraft.wakeTimeMinutes,
      waterMl: waterMl,
      goalPaceKgPerWeek: targetsDraft.goalPaceKgPerWeek,
      heightCm: profileDraft.heightCm,
      currentWeightKg: profileDraft.currentWeightKg,
      targetWeightKg: effectiveProfile.targetWeightKg,
      activityLevel: profileDraft.activityLevel?.name,
      recommendation: recommendation,
    );
  }
}

import 'package:tio_feature_nutrition/nutrition.dart' as nutrition_owner;

import '../models/models.dart';
import 'calculate_nutrition_target_recommendation_use_case.dart';
import 'weight_goal_flow_policy.dart';

/// Pure mapper from Product Onboarding calculation inputs to the canonical
/// Nutrition Targets owner contract.
///
/// The recommendation calculation is intentionally the same one used by the
/// existing Nutrition Target screen. O5D changes persistence ownership only.
class NutritionTargetsMapper {
  const NutritionTargetsMapper({
    this.calculator = const CalculateNutritionTargetRecommendationUseCase(),
    this.weightGoalPolicy = const WeightGoalFlowPolicy(),
  });

  final CalculateNutritionTargetRecommendationUseCase calculator;
  final WeightGoalFlowPolicy weightGoalPolicy;

  nutrition_owner.NutritionTargetsData map(OnboardingDraft draft) {
    final activeWeightDirection = weightGoalPolicy.effectiveDirectionFor(
      mode: draft.selectedMode,
      selection: draft.goalSelection,
      currentWeightKg: draft.profile.currentWeightKg,
      targetWeightKg: draft.profile.targetWeightKg,
    );
    final targetIsActive = activeWeightDirection != null &&
        draft.profile.targetWeightDirection == activeWeightDirection;
    final effectiveProfile = targetIsActive
        ? draft.profile
        : draft.profile.copyWith(clearTargetWeightKg: true);

    // Pace becomes a Nutrition calculation input only when Body has an active
    // loss/gain direction. Training labels never decide surplus/deficit.
    final effectiveTargets = draft.targets.copyWith(
      goalPaceKgPerWeek: activeWeightDirection == null
          ? 0.0
          : draft.targets.goalPaceKgPerWeek,
    );

    final result = calculator(
      profile: effectiveProfile,
      targets: effectiveTargets,
    );

    if (result is nutrition_owner.NutritionTargetRecommendationSuccess) {
      final recommendation = result.recommendation;
      return nutrition_owner.NutritionTargetsData(
        caloriesKcal: recommendation.caloriesKcal,
        proteinGrams: recommendation.proteinGrams.toDouble(),
        carbohydrateGrams: recommendation.carbsGrams.toDouble(),
        fatGrams: recommendation.fatGrams.toDouble(),
        fiberGrams: recommendation.fiberGrams.toDouble(),
        customizationState:
            nutrition_owner.NutritionTargetCustomizationState.recommended,
        customizedFields: const {},
        recommendationMetadata: {
          'source': 'onboarding',
          'bmr': recommendation.bmr,
          'tdee': recommendation.tdee,
        },
      );
    }

    // Existing completion allowed a missing recommendation when calculation
    // inputs were insufficient/invalid. Preserve that semantic behavior by
    // writing an explicit canonical unknown row rather than inventing numeric
    // targets or newly blocking completion in the persistence migration.
    return const nutrition_owner.NutritionTargetsData(
      customizationState:
          nutrition_owner.NutritionTargetCustomizationState.unknown,
      customizedFields: {},
      recommendationMetadata: {'source': 'onboarding'},
    );
  }
}

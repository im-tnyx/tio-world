import 'dart:math' as math;

import '../models/models.dart';

class NutritionTargetCalculator {
  const NutritionTargetCalculator();

  NutritionTargetRecommendationResult calculate(
    NutritionTargetInputs inputs, {
    DateTime? now,
  }) {
    final missingFields = <String>{};
    if (inputs.weightKg == null) missingFields.add('currentWeightKg');
    if (inputs.heightCm == null) missingFields.add('heightCm');
    if (inputs.dateOfBirth == null) missingFields.add('dateOfBirth');
    if (inputs.gender == null) missingFields.add('gender');
    if (inputs.activityLevel == null) missingFields.add('activityLevel');

    if (missingFields.isNotEmpty) {
      return NutritionTargetRecommendationInsufficientInput(
        missingFields: missingFields,
      );
    }

    final weight = inputs.weightKg!;
    final height = inputs.heightCm!;
    final age = inputs.calculateAge(now);

    if (weight <= 0 || height <= 0) {
      return const NutritionTargetRecommendationInvalidInput(
        message: 'Weight and height must be strictly positive values.',
      );
    }

    if (age == null || age <= 0) {
      return const NutritionTargetRecommendationInvalidInput(
        message: 'Date of birth must resolve to a valid age above zero.',
      );
    }

    final bmr = _calculateBmr(
      weightKg: weight,
      heightCm: height,
      ageYears: age,
      gender: inputs.gender!,
    );

    final tdee = _calculateTdee(
      bmr: bmr,
      activityLevel: inputs.activityLevel!,
    );

    final calories = _calculateTargetCalories(
      tdee: tdee,
      primaryGoal: inputs.primaryGoal,
      goalPaceKgPerWeek: inputs.goalPaceKgPerWeek,
    );

    final macros = _calculateMacros(
      targetCalories: calories,
      weightKg: weight,
      primaryGoal: inputs.primaryGoal,
      bmr: bmr,
      tdee: tdee,
    );

    return NutritionTargetRecommendationSuccess(macros);
  }

  int _calculateBmr({
    required double weightKg,
    required double heightCm,
    required int ageYears,
    required String gender,
  }) {
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * ageYears);
    final normalizedGender = gender.trim().toLowerCase();

    final adjusted = switch (normalizedGender) {
      'male' => base + 5,
      'female' => base - 161,
      _ => base - 78,
    };

    return adjusted.round();
  }

  int _calculateTdee({
    required int bmr,
    required String activityLevel,
  }) {
    final normalized = activityLevel.trim().toLowerCase();
    final multiplier = switch (normalized) {
      'sedentary' => 1.2,
      'light' => 1.375,
      'active' => 1.55,
      'veryactive' || 'very_active' => 1.725,
      'dynamic' => 1.9,
      _ => 1.2,
    };

    return (bmr * multiplier).round();
  }

  int _calculateTargetCalories({
    required int tdee,
    required String? primaryGoal,
    required double? goalPaceKgPerWeek,
  }) {
    final goal = primaryGoal?.trim().toLowerCase() ?? 'keep_fit';

    if (goal == 'lose_weight' || goal == 'loseweight') {
      final pace = (goalPaceKgPerWeek != null && goalPaceKgPerWeek > 0)
          ? goalPaceKgPerWeek
          : 0.5;
      final deficit = ((pace * 7700) / 7).round().clamp(150, 1200);
      return math.max(1200, tdee - deficit);
    }

    if (goal == 'build_muscle' ||
        goal == 'buildmuscle' ||
        goal == 'boost_strength' ||
        goal == 'booststrength' ||
        goal == 'gain_muscle' ||
        goal == 'gainmuscle') {
      final pace = (goalPaceKgPerWeek != null && goalPaceKgPerWeek > 0)
          ? goalPaceKgPerWeek
          : 0.3;
      final surplus = ((pace * 5000) / 7).round().clamp(100, 900);
      return tdee + surplus;
    }

    return tdee;
  }

  NutritionTargetRecommendation _calculateMacros({
    required int targetCalories,
    required double weightKg,
    required String? primaryGoal,
    required int bmr,
    required int tdee,
  }) {
    final goal = primaryGoal?.trim().toLowerCase() ?? 'keep_fit';
    final isMaintenance = goal == 'keep_fit' ||
        goal == 'keepfit' ||
        goal == 'manage_stress' ||
        goal == 'managestress' ||
        goal == 'maintenance';

    final proteinPerKg = isMaintenance ? 1.6 : 2.0;
    final proteinGrams = (weightKg * proteinPerKg).round();
    final fatGrams = ((targetCalories * 0.25) / 9).round();

    final proteinCalories = proteinGrams * 4;
    final fatCalories = fatGrams * 9;
    final remainingCalories =
        math.max(0, targetCalories - proteinCalories - fatCalories);
    final carbGrams = (remainingCalories / 4).round();

    final fiberGrams = ((targetCalories / 1000) * 14).round().clamp(25, 50);

    return NutritionTargetRecommendation(
      caloriesKcal: targetCalories,
      proteinGrams: proteinGrams,
      carbsGrams: carbGrams,
      fatGrams: fatGrams,
      fiberGrams: fiberGrams,
      bmr: bmr,
      tdee: tdee,
    );
  }
}

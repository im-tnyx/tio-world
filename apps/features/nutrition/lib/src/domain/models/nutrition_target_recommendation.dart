class NutritionTargetRecommendation {
  const NutritionTargetRecommendation({
    required this.caloriesKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.fiberGrams,
    required this.bmr,
    required this.tdee,
  });

  final int caloriesKcal;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int fiberGrams;
  final int bmr;
  final int tdee;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NutritionTargetRecommendation &&
        other.caloriesKcal == caloriesKcal &&
        other.proteinGrams == proteinGrams &&
        other.carbsGrams == carbsGrams &&
        other.fatGrams == fatGrams &&
        other.fiberGrams == fiberGrams &&
        other.bmr == bmr &&
        other.tdee == tdee;
  }

  @override
  int get hashCode => Object.hash(
        caloriesKcal,
        proteinGrams,
        carbsGrams,
        fatGrams,
        fiberGrams,
        bmr,
        tdee,
      );

  @override
  String toString() {
    return 'NutritionTargetRecommendation(calories: ${caloriesKcal}kcal, '
        'protein: ${proteinGrams}g, carbs: ${carbsGrams}g, '
        'fat: ${fatGrams}g, fiber: ${fiberGrams}g, BMR: $bmr, TDEE: $tdee)';
  }
}

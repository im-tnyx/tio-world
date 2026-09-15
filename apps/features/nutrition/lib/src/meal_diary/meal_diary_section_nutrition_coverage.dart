import 'meal_diary_history_providers.dart';

/// Presentation-safe coverage facts for one Meal Diary section nutrient.
///
/// [exactTotal] remains authoritative only when every entry contains the
/// nutrient. [confirmedTotal] is a lower bound that may be shown with `+` when
/// [missingEntryCount] is non-zero; it must never drive exact progress math.
final class MealDiarySectionNutrientCoverage {
  const MealDiarySectionNutrientCoverage({
    required this.exactTotal,
    required this.confirmedTotal,
    required this.missingEntryCount,
  });

  final num? exactTotal;
  final num? confirmedTotal;
  final int missingEntryCount;

  bool get isIncomplete => exactTotal == null && missingEntryCount > 0;
}

MealDiarySectionNutrientCoverage mealDiarySectionProteinCoverage(
  MealDiarySectionReadModel section,
) {
  final exactTotal = section.proteinGrams;
  if (exactTotal != null) {
    return MealDiarySectionNutrientCoverage(
      exactTotal: exactTotal,
      confirmedTotal: exactTotal,
      missingEntryCount: 0,
    );
  }

  num confirmedTotal = 0;
  var knownCount = 0;
  var missingCount = 0;

  for (final entry in section.entries) {
    final protein = entry.proteinGrams;
    if (protein == null) {
      missingCount++;
    } else {
      knownCount++;
      confirmedTotal += protein;
    }
  }

  return MealDiarySectionNutrientCoverage(
    exactTotal: null,
    confirmedTotal: knownCount == 0 ? null : confirmedTotal,
    missingEntryCount: missingCount,
  );
}

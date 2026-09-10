/// How a meal log was initiated or captured by the user.
///
/// This is meal-level capture intent, not provider identity. A provider or
/// catalog such as FatSecret may resolve the food behind several of these
/// capture modes without changing which mode the user actually used:
///
/// ```text
/// photo + FatSecret recognition   -> photo
/// food search + FatSecret         -> foodSearch
/// barcode + FatSecret lookup      -> barcode
/// ```
///
/// Where a specific structured item originated belongs to a later item-level
/// provenance contract, because one detailed meal may mix items from different
/// origins. Canonical nutrition amounts belong to `NutritionSnapshot`.
enum MealLogCaptureSource {
  quickAdd('quick_add'),
  foodSearch('food_search'),
  barcode('barcode'),
  text('text'),
  voice('voice'),
  photo('photo'),
  recent('recent'),
  savedMeal('saved_meal'),
  plannedMeal('planned_meal');

  const MealLogCaptureSource(this.storageValue);

  /// Stable storage identity. This value is never coupled to presentation.
  final String storageValue;

  /// Decodes a currently supported storage identity.
  ///
  /// Unknown future identities intentionally remain unknown: callers must not
  /// remap them to an existing capture source, and there is deliberately no
  /// fallback, because guessing would fabricate capture intent the user never
  /// expressed.
  static MealLogCaptureSource? fromStorageValue(String? value) {
    for (final source in values) {
      if (source.storageValue == value) return source;
    }

    return null;
  }
}

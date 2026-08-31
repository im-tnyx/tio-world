/// Canonical identity for an editable core Nutrition Target field.
///
/// This is the vocabulary persisted in `user_nutrition_targets.customized_fields`.
/// It is deliberately a **different namespace** from `NutrientId`:
///
/// ```text
/// NutritionTargetField.calories   an editable core target field
/// NutrientId.energy               a nutrient fact identity
/// ```
///
/// They describe the same quantity but answer different questions, so neither
/// is renamed for symmetry with the other. UI may label either as "Calories".
enum NutritionTargetField {
  calories('calories'),
  protein('protein'),
  carbohydrate('carbohydrate'),
  fat('fat'),
  fiber('fiber');

  const NutritionTargetField(this.storageValue);

  /// Stable storage identity written to `customized_fields`.
  final String storageValue;

  /// Decodes a persisted field identity.
  ///
  /// Unknown values stay unknown rather than being remapped onto a neighbouring
  /// field, so a value written by a future version cannot silently change which
  /// target a user marked as customized.
  static NutritionTargetField? fromStorageValue(String? value) {
    for (final field in values) {
      if (field.storageValue == value) return field;
    }

    return null;
  }
}

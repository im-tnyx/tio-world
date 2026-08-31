/// Canonical units for normalized nutrient facts.
///
/// These units are registry metadata, not user display-unit preferences.
enum NutrientUnit {
  kcal('kcal'),
  g('g'),
  mg('mg'),
  mcg('mcg');

  const NutrientUnit(this.storageValue);

  final String storageValue;
}

/// Tio-owned, provider-independent identities for currently justified
/// nutrient facts.
///
/// A nutrient's canonical unit is metadata, not part of its identity. New
/// provider or product evidence may justify more IDs without changing these
/// existing storage values.
enum NutrientId {
  energy('energy', NutrientUnit.kcal),
  protein('protein', NutrientUnit.g),
  carbohydrate('carbohydrate', NutrientUnit.g),
  fat('fat', NutrientUnit.g),
  fiber('fiber', NutrientUnit.g),
  saturatedFat('saturated_fat', NutrientUnit.g),
  transFat('trans_fat', NutrientUnit.g),
  sodium('sodium', NutrientUnit.mg),
  vitaminD('vitamin_d', NutrientUnit.mcg);

  const NutrientId(this.storageValue, this.canonicalUnit);

  /// Stable storage identity. This value is never coupled to the unit.
  final String storageValue;

  /// Canonical unit for amounts represented by this nutrient identity.
  final NutrientUnit canonicalUnit;

  /// Decodes a currently supported storage identity.
  ///
  /// Unknown future identities intentionally remain unknown: callers must not
  /// remap them to an existing nutrient or fail unrelated current data.
  static NutrientId? fromStorageValue(String? value) {
    for (final nutrient in values) {
      if (nutrient.storageValue == value) return nutrient;
    }

    return null;
  }
}

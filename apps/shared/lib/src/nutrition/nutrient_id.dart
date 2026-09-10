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
  energy('energy', NutrientUnit.kcal, false),
  protein('protein', NutrientUnit.g, false),
  carbohydrate('carbohydrate', NutrientUnit.g, false),
  fat('fat', NutrientUnit.g, false),
  fiber('fiber', NutrientUnit.g, false),
  saturatedFat('saturated_fat', NutrientUnit.g, false),
  transFat('trans_fat', NutrientUnit.g, false),
  addedSugar('added_sugar', NutrientUnit.g, false),
  sodium('sodium', NutrientUnit.mg, false),
  calcium('calcium', NutrientUnit.mg, false),
  phosphorus('phosphorus', NutrientUnit.mg, false),
  vitaminD('vitamin_d', NutrientUnit.mcg, false);

  const NutrientId(
    this.storageValue,
    this.canonicalUnit,
    this.derivedOnly,
  );

  /// Stable storage identity. This value is never coupled to the unit.
  final String storageValue;

  /// Canonical unit for amounts represented by this nutrient identity.
  final NutrientUnit canonicalUnit;

  /// Whether this value is calculated rather than reported as a source fact.
  ///
  /// Derived-only nutrients cannot be persisted in a [NutritionSnapshot].
  /// Every currently justified registry entry is a source fact; the flag keeps
  /// that invariant explicit when future registry entries are considered.
  final bool derivedOnly;

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

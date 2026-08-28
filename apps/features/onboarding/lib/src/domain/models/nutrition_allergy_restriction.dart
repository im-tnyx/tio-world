enum NutritionAllergyRestriction {
  none,
  lactose,
  gluten,
  nuts,
  seafood,
  other;

  String get storageValue => name;

  static NutritionAllergyRestriction? tryFromStorage(Object? value) {
    if (value is! String) return null;
    for (final restriction in NutritionAllergyRestriction.values) {
      if (restriction.storageValue == value) return restriction;
    }
    return null;
  }
}

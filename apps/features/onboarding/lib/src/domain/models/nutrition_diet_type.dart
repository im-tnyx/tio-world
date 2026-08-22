enum NutritionDietType {
  vegetarian,
  nonVegetarian,
  vegan,
  eggitarian,
  other;

  String get storageValue => switch (this) {
        NutritionDietType.vegetarian => 'vegetarian',
        NutritionDietType.nonVegetarian => 'non_vegetarian',
        NutritionDietType.vegan => 'vegan',
        NutritionDietType.eggitarian => 'eggitarian',
        NutritionDietType.other => 'other',
      };

  static NutritionDietType? tryFromStorage(Object? value) => switch (value) {
        'vegetarian' => NutritionDietType.vegetarian,
        'non_vegetarian' || 'nonVegetarian' => NutritionDietType.nonVegetarian,
        'vegan' => NutritionDietType.vegan,
        'eggitarian' => NutritionDietType.eggitarian,
        'other' => NutritionDietType.other,
        _ => null,
      };
}

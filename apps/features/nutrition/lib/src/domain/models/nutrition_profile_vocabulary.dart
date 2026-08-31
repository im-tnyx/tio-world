/// Canonical Nutrition Profile selection vocabulary.
///
/// These storage values must stay byte-identical to the values Product
/// Onboarding's accepted O5 mapper writes, because both surfaces persist
/// through the same `NutritionProfileRepository` into
/// `user_nutrition_profiles`. Onboarding owns its own step enums; this
/// vocabulary is the canonical owner-side view used by post-onboarding
/// editors, so Settings never imports Onboarding presentation code.
///
/// Parity with the Onboarding enums is asserted by a composition-root test
/// (`apps/app`), which is the only layer that legitimately depends on both.
abstract final class NutritionProfileVocabulary {
  /// Diet Type storage values, in accepted display order.
  ///
  /// `other` is a real selectable canonical value. Onboarding additionally
  /// keeps a free-text elaboration in its local draft, but that text has no
  /// canonical column and is intentionally not persisted, so post-onboarding
  /// editing exposes the selection only.
  static const dietTypes = <NutritionChoice>[
    NutritionChoice(storageValue: 'vegetarian', label: 'Vegetarian'),
    NutritionChoice(storageValue: 'non_vegetarian', label: 'Non-Vegetarian'),
    NutritionChoice(storageValue: 'vegan', label: 'Vegan'),
    NutritionChoice(storageValue: 'eggitarian', label: 'Eggitarian'),
    NutritionChoice(storageValue: 'other', label: 'Other'),
  ];

  /// Allergy/restriction storage values, in accepted display order.
  ///
  /// `none` is deliberately absent: the canonical contract represents an
  /// explicit "None" answer as an empty set, never as a stored token.
  static const allergies = <NutritionChoice>[
    NutritionChoice(storageValue: 'lactose', label: 'Lactose'),
    NutritionChoice(storageValue: 'gluten', label: 'Gluten'),
    NutritionChoice(storageValue: 'nuts', label: 'Nuts'),
    NutritionChoice(storageValue: 'seafood', label: 'Seafood'),
    NutritionChoice(storageValue: 'other', label: 'Other'),
  ];

  /// Human label for a persisted Diet Type value, or null when unknown.
  ///
  /// An unrecognised historical value returns null rather than being silently
  /// rewritten, so an unexpected row is displayed truthfully as unset.
  static String? dietTypeLabel(String? storageValue) {
    if (storageValue == null) return null;
    for (final choice in dietTypes) {
      if (choice.storageValue == storageValue) return choice.label;
    }
    return null;
  }

  /// Human labels for persisted allergy values, preserving display order and
  /// dropping unrecognised historical tokens from the summary only.
  static List<String> allergyLabels(Set<String> storageValues) {
    return [
      for (final choice in allergies)
        if (storageValues.contains(choice.storageValue)) choice.label,
    ];
  }
}

/// One canonical selectable value plus its display label.
class NutritionChoice {
  const NutritionChoice({required this.storageValue, required this.label});

  final String storageValue;
  final String label;
}

/// Canonical Nutrition Profile context owned by `user_nutrition_profiles`.
///
/// This model intentionally excludes common Profile, Body, Wellness, and
/// numeric Nutrition target concepts even while legacy columns remain in the
/// physical table during the additive migration.
///
/// Nullable collections preserve the live-schema distinction between an
/// unknown/unset value (`null`) and an explicitly empty selection (`{}`).
class NutritionProfileData {
  const NutritionProfileData({
    this.preferredDiet,
    this.allergies,
    this.dislikedFoods,
    this.medicalConditions,
    this.otherDietType,
    this.otherAllergyRestriction,
  });

  final String? preferredDiet;
  final Set<String>? allergies;
  final Set<String>? dislikedFoods;
  final Set<String>? medicalConditions;

  /// Free-text elaboration for [preferredDiet] when it is `other`.
  ///
  /// A bare `other` selection records that a diet exists without recording
  /// which one, so this carries the answer itself. `null` means unanswered or
  /// deliberately left blank; an empty string is never stored.
  final String? otherDietType;

  /// Free-text elaboration for the `other` entry in [allergies].
  ///
  /// This is the only place an unlisted restriction (sesame, soy, shellfish)
  /// can be recorded, so downstream diet planning must treat it as real
  /// restriction data rather than a display-only note.
  final String? otherAllergyRestriction;
}

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
  });

  final String? preferredDiet;
  final Set<String>? allergies;
  final Set<String>? dislikedFoods;
  final Set<String>? medicalConditions;
}

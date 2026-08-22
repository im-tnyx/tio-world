import '../models/nutrition_profile_data.dart';

/// Canonical Nutrition Profile owner boundary.
abstract interface class NutritionProfileRepository {
  /// Returns the authenticated user's Nutrition Profile context, or null when
  /// signed out or when no canonical row exists.
  Future<NutritionProfileData?> read();

  /// Replaces canonical Nutrition Profile context values for the authenticated
  /// user. Nulls are intentional unknown/clear values, not default requests.
  Future<void> upsert(NutritionProfileData profile);
}
